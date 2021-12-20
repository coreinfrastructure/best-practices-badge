# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
    @admin_user = users(:admin_user)
  end

  test 'unsuccessful index without logging in' do
    get users_path(locale: :en)
    assert_redirected_to login_url(locale: :en)
  end

  test 'Can request index, but non-admins do not get email addresses' do
    log_in_as(@user)
    get users_path
    assert_response :success
    assert_template 'index'
    assert_not @response.body.include?(@user.email)
  end

  test 'Can request index.json, but non-admins do not get email addresses' do
    log_in_as(@user)
    get users_path + '.json'
    assert_response :success
    assert_not @response.body.include?(@user.email)
  end

  test 'successful index as admin, admins do get email addresses' do
    log_in_as(@admin_user)
    get users_path
    assert_response :success
    assert_template 'index'
    assert @response.body.include?(@user.email)
  end
end
