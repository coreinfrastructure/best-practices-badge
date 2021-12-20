# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

module ClientIp
  # Compute the correct remote IP address for our environment.
  # We have done tests, and in our current environment this is the
  # always the next-to-last value of the comma-space-separated value
  # "HTTP_X_FORWARDED_FOR" (from the HTTP header X-Forwarded-For).
  # That's because the last value of "HTTP_X_FORWARDED_FOR"
  # is always our CDN (which intercepts it first), and the previous
  # value is set by our CDN to whatever IP address the CDN got.
  # A client can always set X-Forwarded-For and try to spoof something,
  # but those entries are always earlier in the list
  # (so we can easily ignore them).
  # Use correct_remote_ip(req) instead of req.ip.
  def self.acquire(req)
    forwarding = req.get_header('HTTP_X_FORWARDED_FOR')
    if forwarding
      # Production environment, pick next-to-last value
      forwarding.split(', ')[-2]
    else
      # Test/development environment, do the best you can.
      req.ip
    end
  end
end
