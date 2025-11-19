# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'ipaddr'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # These are special tests for how the ApplicationController works,
  # in particular for handling IP addresses.

  test 'fail_if_invalid_client_ip works correctly' do
    a = ApplicationController.new
    client_ip = '43.249.72.2'
    range1 = IPAddr.new('23.235.32.0/20')
    range2 = IPAddr.new('43.249.72.0/22')

    assert_nothing_raised { a.send(:fail_if_invalid_client_ip, '', []) }
    assert_raises { a.send(:fail_if_invalid_client_ip, client_ip, []) }
    assert_nothing_raised do
      a.send(:fail_if_invalid_client_ip, client_ip, [range1, range2])
    end
    assert_raises do
      a.send(:fail_if_invalid_client_ip, client_ip, [range1, range1])
    end
  end

  test 'check if validate_client_ip_address runs when valid_client_ips' do
    Rails.configuration.valid_client_ips = [IPAddr.new('23.235.32.0/24')]
    a = ApplicationController.new
    a.request = ActionDispatch::Request.new({})
    a.request.env['REMOTE_ADDR'] = '1.2.3.4' # Not valid!
    assert_raises { a.send(:validate_client_ip_address) }

    a.request = ActionDispatch::Request.new({})
    a.request.env['REMOTE_ADDR'] = '23.235.32.1' # Valid!
    assert_nothing_raised { a.send(:validate_client_ip_address) }
    Rails.configuration.valid_client_ips = nil # Clean up.
  end

  test 'normalize_criteria_level handles baseline levels' do
    a = ApplicationController.new
    assert_equal 'baseline-1', a.normalize_criteria_level('baseline-1')
    assert_equal 'baseline-2', a.normalize_criteria_level('baseline-2')
    assert_equal 'baseline-3', a.normalize_criteria_level('baseline-3')
  end

  test 'normalize_criteria_level handles invalid input with default fallback' do
    a = ApplicationController.new
    assert_equal 'passing', a.normalize_criteria_level('invalid')
    assert_equal 'passing', a.normalize_criteria_level('999')
    assert_equal 'passing', a.normalize_criteria_level('')
  end

  test 'criteria_level_to_internal handles baseline levels' do
    a = ApplicationController.new
    assert_equal 'baseline-1', a.criteria_level_to_internal('baseline-1')
    assert_equal 'baseline-2', a.criteria_level_to_internal('baseline-2')
    assert_equal 'baseline-3', a.criteria_level_to_internal('baseline-3')
  end

  test 'criteria_level_to_internal handles invalid input with default fallback' do
    a = ApplicationController.new
    assert_equal '0', a.criteria_level_to_internal('invalid')
    assert_equal '0', a.criteria_level_to_internal('999')
    assert_equal '0', a.criteria_level_to_internal('')
  end
end
