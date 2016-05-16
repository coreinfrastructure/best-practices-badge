# frozen_string_literal: true
require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
  end

  test 'login with invalid username and password' do
    get login_path
    assert_template 'sessions/new'
    post login_path,
         session: {
           email: 'unknown@example.org', password: 'bad_password',
           provider: 'local'
         }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test 'login with no provider' do
    get login_path
    assert_template 'sessions/new'
    post login_path,
         session: { email: 'unknown@example.org', password: 'bad_password' }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  # See the comments on test_helper.rb method log_in_as()
  test 'login with valid information and then logout' do
    # To skip: skip('message')
    get login_path
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

    delete logout_path
    assert_not user_logged_in?
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'a[href=?]'.dup, login_path
    assert_select 'a[href=?]'.dup, logout_path,      count: 0
    assert_select 'a[href=?]'.dup, user_path(@user), count: 0
  end

  test 'login with remembering' do
    log_in_as(@user, remember_me: '1')
    assert_not_nil cookies['remember_token']
  end

  test 'login without remembering' do
    log_in_as(@user, remember_me: '0')
    assert_nil cookies['remember_token']
  end
end
