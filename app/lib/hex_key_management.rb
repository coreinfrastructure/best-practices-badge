# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Shared pattern for "a hex-encoded secret key with a test-environment
# fallback", used by User's email encryption/blind-index keys and
# LoginSession's session id HMAC key. In test mode, always return
# test_value, so tests are self-contained regardless of shell/CI
# environment variables; otherwise fall back to test_value only if the
# real env var isn't set (which must never happen in staging/production;
# see docs/login-session-implementation.md section 1).
module HexKeyManagement
  def hex_key_for(env_var:, test_value:, env_test: Rails.env.test?)
    return test_value if env_test

    ENV[env_var] || test_value
  end
end
