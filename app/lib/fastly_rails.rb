# frozen_string_literal: true

# Copyright OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Enable Fastly support from Rails.
# We once used the fastly-rails gem, but that doesn't support Rails 6.
# The fastly (fastly-ruby) gem doesn't support threads (!).
# So we'll just call the purge API directly, as recommended in:
# https://github.com/fastly/fastly-ruby
# See also:
# https://developer.fastly.com/reference/api/purging/
# https://developer.fastly.com/reference/api/auth/

# We could require 'net/http', but that needs more code for HTTPS.

class FastlyRails
  include HTTParty

  # Base of API. To create a "dead port" after .com append ":444" or some
  # other unused port
  # FASTLY_BASE = 'https://api.fastly.com'
  FASTLY_BASE = 'https://api.fastly.com'
  FASTLY_API_KEY = ENV['FASTLY_API_KEY'].to_s
  FASTLY_OPTIONS = {
    headers: { 'Fastly-Key': FASTLY_API_KEY },
    timeout: 10 # seconds
  }.freeze
  FASTLY_SERVICE_ID = ENV['FASTLY_SERVICE_ID'].to_s

  # Purge the CDN resources associated with this key
  # Use "force" to force a post even when we have no key or service id
  # (this is used for testing).
  # We'll squelch exceptions, we'd rather keep going than fail if the
  # cache fails.
  # rubocop:disable Metrics/MethodLength
  def self.purge_by_key(key, force = false, base = FASTLY_BASE)
    return if !force && (FASTLY_API_KEY.blank? || FASTLY_SERVICE_ID.blank?)

    begin
      # We'll return the result, but normally that will be ignored.
      HTTParty.post(
        "#{base}/service/#{FASTLY_SERVICE_ID}/purge/#{key}",
        FASTLY_OPTIONS
      )
    rescue StandardError => e
      # I hate catching StandardError, ideally we'd be more specific.
      # However, there doesn't seem to be a safe way to identify
      # all network-based exceptions. See:
      # https://stackoverflow.com/questions/5370697/
      # what-s-the-best-way-to-handle-exceptions-from-nethttp
      # For example, this does NOT work:
      # rescue HTTParty::Error, Net::OpenTimeout, IOError => e
      Rails.logger.error do
        "ERROR:: FAILED TO PURGE #{key} , #{e.class}: #{e}"
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def self.purge_all(force = false, base = FASTLY_BASE)
    return if !force && (FASTLY_API_KEY.blank? || FASTLY_SERVICE_ID.blank?)

    begin
      # We'll return the result, but normally that will be ignored.
      # https://developer.fastly.com/reference/api/purging/
      # We won't ask for a "soft purge" because purge-all doesn't support it.
      HTTParty.post(
        "#{base}/service/#{FASTLY_SERVICE_ID}/purge_all",
        FASTLY_OPTIONS
      )
    rescue StandardError => e
      # I hate catching StandardError, ideally we'd be more specific.
      # However, there doesn't seem to be a safe way to identify
      # all network-based exceptions. See:
      # https://stackoverflow.com/questions/5370697/
      # what-s-the-best-way-to-handle-exceptions-from-nethttp
      # For example, this does NOT work:
      # rescue HTTParty::Error, Net::OpenTimeout, IOError => e
      Rails.logger.error do
        "ERROR:: FAILED TO PURGE_ALL, #{e.class}: #{e}"
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
