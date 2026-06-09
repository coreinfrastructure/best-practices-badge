# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'ssrf_filter'
require 'security_utils'

# This class collects and caches all evidence gathered so far on a project.
# If parallel execution is possible, this class locks/unlocks so
# parallel writing doesn't cause any harm.
# It defends itself, e.g., from domain URLs that map to
# reserved IP addresses.
#
# NOTE: The current plan is to remove this class, it's not helping much.
class Evidence
  # Initialize an Evidence collector for a project.
  #
  # @param project [Project] The ActiveRecord project instance.
  # @param resolver [Proc, #resolve] Optional DNS resolver for ssrf_filter,
  #   primarily for testing.
  def initialize(project, resolver: nil)
    @project = project # ActiveRecord. Detectives should NOT change this.
    @cached_data = {}
    @resolver = resolver
  end

  attr_reader :project

  # Don't download more than this number of bytes per file;
  # this helps counter easy DoS attacks.
  MAXREAD = 1 * (2**20)

  # Get contents of given URL and return it (cached).
  # Returns a hash with :meta (headers) and :body (content) if successful.
  #
  # @param url [String] The URL to fetch data from.
  # @return [Hash, nil] The fetched data or nil if the URL is invalid or the
  #   fetch fails.
  #
  # TODO: Handle exceptions - turn into nothing useful.
  # TODO: Lock for parallel access. Possibly return while still reading.
  # TODO: Timeout on reads.
  # rubocop:disable Metrics/MethodLength
  def get(url)
    return if url.blank?

    unless @cached_data.key?(url)
      # Security: Ignore dubious URLs (SSRF protection & possible attack)
      if SecurityUtils.dubious_url?(url)
        Rails.logger.warn "Ignoring dubious URL for evidence: #{url}"
        @cached_data[url] = nil
        return
      end

      begin
        # Use ssrf_filter to ensure GET requests are not performed if the
        # domain dynamically resolves (possibly via redirects) to a
        # reserved IP address (IPv4 or IPv6) like 127.0.0.1.
        # Note that ssrf_filter checks on *every* request; attackers might
        # dynamically switch DNS resolution between valid and invalid
        # IP addresses, which we catch by checking each time.
        options = {}
        options[:resolver] = @resolver if @resolver
        SsrfFilter.get(url, options) do |res|
          # Only process successful responses
          if res.is_a?(Net::HTTPSuccess)
            body = (+'').force_encoding('BINARY')
            res.read_body do |chunk|
              body << chunk
              break if body.bytesize >= MAXREAD
            end
            # Truncate if we went over in the last chunk
            body = body.byteslice(0, MAXREAD) if body.bytesize > MAXREAD

            # meta in open-uri is a hash-like object of headers
            # We convert Net::HTTP headers to a simple hash
            meta = res.to_hash.transform_values { |v| v.join(', ') }
            @cached_data[url] = { meta: meta, body: body }
          else
            @cached_data[url] = nil
          end
        end
      rescue SsrfFilter::Error, StandardError => e
        # Skip if error - use what we have, if anything.
        Rails.logger.warn "Error fetching URL #{url}: #{e.message}"
        @cached_data[url] ||= nil
      end
    end
    @cached_data[url]
  end
  # rubocop:enable Metrics/MethodLength
end
