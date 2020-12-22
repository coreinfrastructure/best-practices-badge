# frozen_string_literal: true

# Copyright the CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class BadPasswordTest < ActiveSupport::TestCase
  test 'Bad password found in BadPassword' do
    assert BadPassword.exists?(forbidden: '123456')
  end

  test 'Good password not found in BadPassword' do
    assert_not BadPassword.exists?(forbidden: 'asjfdksajdklfajdfkjaslkdfj')
  end
end
