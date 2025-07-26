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

  # Running BadPassword.force_load without limit would take a *long* time.
  # For testing purposes, we load a few values and make sure it's found.
  test 'Load full bad password list' do
    BadPassword.force_load
    assert BadPassword.unlogged_exists?('10101010')
    assert_not BadPassword.unlogged_exists?('A_decent_pass_Maybe?_581905012')
  end
end
