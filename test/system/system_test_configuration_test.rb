# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'application_system_test_case'

# Test that system test environment is configured correctly
class SystemTestConfigurationTest < ApplicationSystemTestCase
  test 'force_ssl is disabled in test environment' do
    # With force_ssl disabled, the test server uses HTTP not HTTPS
    # This prevents SSL redirect errors in system tests
    assert_equal false, Rails.configuration.force_ssl,
                 'force_ssl must be false to avoid HTTPS redirects in tests'
  end

  test 'can visit home page without SSL errors' do
    # This test verifies system tests work without SSL errors
    visit '/'

    # Should redirect to locale path like /en/ or /fr/
    # Note that Ruby regex uses \A...\z, not ^...$, for full string matches
    assert_current_path %r{\A/[a-z]{2}(_[A-Z]{2})?/?\z}
    # More specifically, it should be English if unspecified
    assert_current_path %r{\A/en/?\z}
    # Should successfully load text without SSL errors
    assert_selector 'body', text: 'Best Practices'
  end
end
