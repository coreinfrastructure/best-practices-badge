# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

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
end
