# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Shared pattern for "a hex-encoded secret key with a test-environment
# fallback", used by User's email encryption/blind-index keys,
# LoginSession's session id HMAC key, and PendingResubmission's token
# HMAC key (docs/login-session-evaluation.md finding #9: previously
# copy-pasted per model). In test mode, always test_value, so tests are
# self-contained regardless of shell/CI environment variables; otherwise
# env_var's value, falling back to test_value only if unset (must never
# happen in staging/production; see
# docs/login-session-implementation.md section 1).
module HexKeyManagement
  def hex_key_for(env_var:, test_value:, env_test: Rails.env.test?)
    return test_value if env_test

    ENV[env_var] || test_value
  end

  # Raw key bytes for hex_key_for's result. Call once, at class-load
  # time, and store the result in a constant (finding #8): re-deriving
  # this on every use would repeat both the ENV read and the allocation.
  def hex_key(env_var:, test_value:)
    [hex_key_for(env_var: env_var, test_value: test_value)].pack('H*')
  end
end
