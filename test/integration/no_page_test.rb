# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class NoPageTest < ActionDispatch::IntegrationTest
  test 'Non-locale boring no such page redirects to 404' do
    get '/i-do-not-exist'
    assert_response :found
    follow_redirect!
    assert_response :missing
    assert_template 'static_pages/error_404'
  end

  test 'No such page in a locale returns 404' do
    get '/en/i-do-not-exist'
    assert_response :missing
    assert_template 'static_pages/error_404'
  end

  test 'No such page in well-known returns 404' do
    get '/.well-known/i-do-not-exist'
    assert_response :missing
    assert_template 'static_pages/error_404'
  end
end
