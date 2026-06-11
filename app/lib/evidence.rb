# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'ssrf_filter'
require 'security_utils'
require 'timeout'

# This class collects and caches all evidence gathered so far on a project.
# This class is security-sensitive; here we gather evidence by doing a GET
# of untrusted data via URLs derived from data from untrusted users.
# As a result, this class must defend itself, e.g., from domain URLs that
# map to reserved IP addresses, slowloris attacks, no/slow response, and
# excessive data or header size.
#
# rubocop:disable Metrics/ClassLength
class Evidence
  # Initialize an Evidence collector for a project.
  #
  # @param project [Project] The ActiveRecord project instance.
  # @param resolver [Proc, #resolve] Optional DNS resolver for ssrf_filter,
  #   primarily for testing.
  # @param allow_private_ips [Boolean] If true, allow fetching from private
  #   IP addresses (e.g., for internal use). Defaults to the value of the
  #   ALLOW_PRIVATE_IPS environment variable. Option for testing.
  def initialize(
    project,
    resolver: CachedDnsResolver,
    allow_private_ips: ENV['ALLOW_PRIVATE_IPS'] == 'true'
  )
    @project = project # ActiveRecord. Detectives should NOT change this.
    @cached_data = {}
    @resolver = resolver
    @allow_private_ips = allow_private_ips
  end

  attr_reader :project

  # Don't download more than this number of bytes per file;
  # this helps counter easy DoS attacks.
  MAXREAD = 1 * (2**20)

  # Don't wait more than this many seconds for a response (connection + body).
  MAX_TOTAL_TIME = 10

  # Don't store more than this many bytes of HTTP headers.
  MAX_HEADER_SIZE = 64 * 1024

  # Get contents of given URL and return it (cached).
  # Returns a hash with :meta (headers) and :body (content) if successful.
  #
  # @param url [String] The URL to fetch data from.
  # @return [Hash, nil] The fetched data or nil if the URL is invalid or the
  #   fetch fails.
  def get(url)
    return if url.blank?

    unless @cached_data.key?(url)
      # Security: Ignore dubious URLs (SSRF protection & possible attack).
      # They *should* already have been rejected earlier when we did input
      # validation, but we re-validate this here to *ensure* we ignore them.
      # It's a quick check, so there's no real downside to
      # re-performing the check here as well as during
      # input validation earlier, and that way we *ensure* we ignore
      # dubious URLs like `https://127.0.0.1`.
      if SecurityUtils.dubious_url?(url)
        Rails.logger.warn "Ignoring dubious URL for evidence: #{url}"
        @cached_data[url] = nil
      else
        fetch_url_with_timeout(url)
      end
    end
    @cached_data[url]
  end

  private

  # Fetch data from the URL with a global timeout.
  #
  # @param url [String] The URL to fetch data from.
  # @return [void]
  def fetch_url_with_timeout(url)
    Timeout.timeout(MAX_TOTAL_TIME) do
      if @allow_private_ips
        get_insecure(url)
      else
        get_secure(url)
      end
    end
  rescue StandardError => e
    handle_fetch_error(url, e)
  end

  # Log error and mark the URL as failed in the cache.
  #
  # @param url [String] The URL that failed.
  # @param error [StandardError] The error that occurred.
  # @return [void]
  def handle_fetch_error(url, error)
    msg =
      if error.is_a?(Timeout::Error)
        "Timeout (> #{MAX_TOTAL_TIME}s)"
      else
        "Error: #{error.message}"
      end
    Rails.logger.warn "#{msg} fetching URL #{url}"
    @cached_data[url] = nil
  end

  # Extract the body from the response, respecting MAXREAD.
  #
  # @param res [Net::HTTPResponse] The response object.
  # @return [String] The frozen body string.
  def extract_body(res)
    body = (+'').force_encoding('BINARY')
    res.read_body do |chunk|
      body << chunk
      break if body.bytesize >= MAXREAD
    end
    # Truncate if we went over in the last chunk
    body.byteslice(0, MAXREAD).freeze
  end

  # Extract and limit headers from the response to prevent resource exhaustion.
  #
  # @param res [Net::HTTPResponse] The response object.
  # @return [Hash<String, String>] The frozen metadata hash.
  def extract_meta(res)
    limit_headers(res.to_hash.transform_values { |v| v.join(', ') })
  end

  # Perform a secure GET request using ssrf_filter, to prevent
  # reserved (private) IP address use.
  #
  # @param url [String] The URL to fetch data from.
  # @return [void]
  # rubocop:disable Metrics/MethodLength
  def get_secure(url)
    # Use ssrf_filter to ensure GET requests are not performed if the
    # domain dynamically resolves (possibly via redirects) to a
    # reserved IP address (either IPv4 or IPv6) such as 127.0.0.1.
    options = {
      open_timeout: 5,
      read_timeout: 5,
      headers: { 'User-Agent' => USER_AGENT }
    }
    options[:resolver] = @resolver if @resolver
    SsrfFilter.get(url, options) do |res|
      # Only process successful responses
      @cached_data[url] =
        if res.is_a?(Net::HTTPSuccess)
          {
            meta: extract_meta(res), body: extract_body(res)
          }.freeze
        end
    end
  rescue SsrfFilter::Error => e
    Rails.logger.warn "SSRF Filter error fetching URL #{url}: #{e.message}"
    @cached_data[url] ||= nil
  end
  # rubocop:enable Metrics/MethodLength

  # Perform an insecure GET request (allows private IPs) using open-uri.
  # This is only used if ALLOW_PRIVATE_IPS is set.
  #
  # @param url [String] The URL to fetch data from.
  # @return [void]
  # rubocop:disable Metrics/MethodLength
  def get_insecure(url)
    require 'open-uri'
    URI.parse(url).open(
      'rb',
      'User-Agent' => USER_AGENT,
      open_timeout: 5,
      read_timeout: 5
    ) do |file|
      meta = extract_open_uri_meta(file)
      @cached_data[url] = {
        meta: meta, body: file.read(MAXREAD).freeze
      }.freeze
    end
  rescue StandardError => e
    Rails.logger.warn "Error fetching URL #{url} (insecure): #{e.message}"
    @cached_data[url] ||= nil
  end
  # rubocop:enable Metrics/MethodLength

  # Extract headers from open-uri file result.
  #
  # @param file [StringIO, Tempfile] The file object from open-uri.
  # @return [Hash<String, String>] The frozen metadata hash.
  def extract_open_uri_meta(file)
    limit_headers(file.meta)
  end

  # Limit headers by size and freeze them.
  #
  # @param headers [Hash<String, String>] The raw headers.
  # @return [Hash<String, String>] The frozen metadata hash.
  def limit_headers(headers)
    current_size = 0
    headers.each_with_object({}) do |(k, v), hash|
      val = v.freeze
      item_size = k.bytesize + val.bytesize
      if current_size + item_size > MAX_HEADER_SIZE
        Rails.logger.warn 'Evidence: Headers > MAX_HEADER_SIZE; truncated.'
        break hash.freeze
      end
      hash[k] = val
      current_size += item_size
    end.freeze
  end
end
# rubocop:enable Metrics/ClassLength
