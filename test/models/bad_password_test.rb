# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class BadPasswordTest < ActiveSupport::TestCase
  test 'Bad password found in BadPassword' do
    assert BadPassword.exists?(forbidden: '123456')
  end

  test 'Good password not found in BadPassword' do
    assert_not BadPassword.exists?(forbidden: 'asjfdksajdklfajdfkjaslkdfj')
  end

  test 'Ensure that we have small bad password list for tests' do
    assert_not BadPassword.exists?(forbidden: '10101010')
  end

  test 'Load full bad password list' do
    BadPassword.force_load
    assert BadPassword.exists?(forbidden: '10101010')
  end
end
