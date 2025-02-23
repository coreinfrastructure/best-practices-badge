# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class BadPasswordTest < ActiveSupport::TestCase
  test 'Bad password found in BadPassword' do
    assert BadPassword.unlogged_exists?('123456')
  end

  test 'Good password not found in BadPassword' do
    assert_not BadPassword.unlogged_exists?('asjfdksajdklfajdfkjaslkdfj')
  end

  # We don't run BadPassword.force_load in the test suite.
  # It takes a long time to run.
  # test 'Load full bad password list' do
  #   BadPassword.force_load
  #   assert BadPassword.unlogged_exists?('10101010')
  # end
end
