# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'security_utils'

class SecurityUtilsTest < ActiveSupport::TestCase
  test 'security_assertion does nothing if condition is true' do
    assert_nothing_raised { SecurityUtils.security_assertion(true, 'Should not raise') }
  end

  test 'security_assertion raises SecurityAssertionError if condition is false' do
    err =
      assert_raises(SecurityUtils::SecurityAssertionError) do
        SecurityUtils.security_assertion(false, 'My error message')
      end
    assert_match(/SECURITY CRITICAL: My error message/, err.message)
  end
end
