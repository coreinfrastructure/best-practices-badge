# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class AdminUsersShowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
    @admin_user = users(:admin_user)
    @melissa = users(:test_user_melissa)
  end

  test 'non-logged-in show user' do
    get user_path(@melissa, locale: :en)
    assert_response :success
    assert_select(+'a[href=?]', 'mailto:melissa%40example.com', false)
  end

  test 'non-admin show user' do
    log_in_as(@user)
    get user_path(@melissa, locale: :en)
    assert_response :success
    assert_select(+'a[href=?]', 'mailto:melissa%40example.com', false)
  end

  test 'admin show user' do
    log_in_as(@admin_user)
    get user_path(@melissa, locale: :en)
    assert_response :success
    assert_select(+'a[href=?]', 'mailto:melissa%40example.com')
  end
end
