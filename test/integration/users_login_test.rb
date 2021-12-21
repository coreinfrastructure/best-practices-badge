# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
    @user2 = users(:test_user_not_active)
  end

  test 'login with invalid username and password' do
    get login_path, params: { locale: 'en' }
    assert_template 'sessions/new'
    post login_path, params: {
      session: {
        email: 'unknown@example.org', password: 'bad_password',
        provider: 'local'
      }
    }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test 'login with no provider' do
    get login_path, params: { locale: 'en' }
    assert_template 'sessions/new'
    post login_path, params: {
      session: { email: 'unknown@example.org', password: 'bad_password' }
    }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  # See the comments on test_helper.rb method log_in_as()
  test 'login with valid information and then logout' do
    # To skip: skip('message')
    get login_path, params: { locale: 'en' }
    assert_template 'sessions/new'

    log_in_as @user

    assert user_logged_in?
    # If we redirect users to @user on login:
    # assert_redirected_to @user
    # follow_redirect!
    # assert_template 'users/show'
    # assert_select 'a[href=?]', login_path, count: 0
    # assert_select 'a[href=?]', logout_path
    # assert_select 'a[href=?]', user_path(@user)

    delete logout_path, params: { locale: 'en' }
    assert_not user_logged_in?
    assert_redirected_to root_url(locale: :en)
    follow_redirect!
    # Parentheses necessary to avoid Rubocop Lint/AmbiguousOperator error
    assert_select(+'a[href=?]', login_path(locale: :en))
    assert_select(+'a[href=?]', logout_path(locale: :en), count: 0)
    assert_select(+'a[href=?]', user_path(@user, locale: :en), count: 0)
  end

  test 'login with valid information but not activated' do
    log_in_as @user2
    assert_not user_logged_in?
    assert_redirected_to root_url(locale: :en)
    assert_not flash.empty?
  end

  test 'login with remembering' do
    log_in_as(@user, remember_me: '1')
    assert_not_nil cookies['remember_token']
    # Make sure this cookie is encrypted!
    assert_equal 22, cookies['remember_token'].length
    assert_not_includes cookies['remember_token'], 'password'
  end

  test 'login without remembering' do
    log_in_as(@user, remember_me: '0')
    assert_nil cookies['remember_token']
  end
end
