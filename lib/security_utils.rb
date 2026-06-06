# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'ipaddr'
require 'uri'

# Security utility methods
module SecurityUtils
  class SecurityAssertionError < StandardError; end

  # This method is used to enforce security invariants at load time.
  # It is a "fail-fast" mechanism to prevent the application from
  # booting if a security check fails.
  # It has a special name to ensure it is *always* called in production
  # at startup.
  # By using a method for this, we can test the error-raising branch
  # in unit tests to satisfy 100% statement coverage requirements.
  def self.security_assertion(condition, message)
    raise SecurityAssertionError, "SECURITY CRITICAL: #{message}" unless condition
  end

  # Returns true if the URL is dubious (potentially dangerous or malformed).
  # This enforces a "Domain Only" policy for public project URLs:
  # 1. Rejects all IP addresses (IPv4, IPv6, hex, integer formats).
  # 2. Requires at least one dot in the hostname (rejects localhost, internal
  #    network hostnames, and malformed entries like 'containrrr').
  # 3. Only allows http and https protocols.
  # rubocop:disable Metrics/MethodLength
  def self.dubious_url?(url)
    # Empty/nil URLs are not "dubious" themselves; the caller should
    # decide if empty values are acceptable.
    return false if url.nil? || url.to_s.strip.empty?

    begin
      uri = URI.parse(url.to_s.strip)
      return true unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      host = uri.host
      return true if host.nil? || host.strip.empty?

      # Requirement: At least one dot in hostname (blocks localhost, containrrr, etc.)
      return true if host.exclude?('.')

      # Requirement: No IP addresses (IPv4 or IPv6)
      # Normal public OSS projects use domain names.
      # This provides robust SSRF protection.
      begin
        IPAddr.new(host)
        return true # It's a valid IP address
      rescue IPAddr::InvalidAddressError
        # Check for numeric-only or hex-like hosts (e.g. 0x7f000001, 127.1, 2130706433)
        # These are often used for SSRF bypasses.
        return true if host.match?(/\A(0x[0-9a-f]+|[0-9.]+)\z/i)
      end
    rescue URI::InvalidURIError
      return true
    end
    false
  end
  # rubocop:enable Metrics/MethodLength
end
