# frozen_string_literal: true

require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test 'invalid signup information' do
    assert_no_difference 'User.count' do
      post users_path, params: { user: {
        name:  '',
        email: 'user@invalid',
        password:              'foo',
        password_confirmation: 'bar'
      } }
    end
    assert_template 'users/new'
  end

  test 'reject bad passwords' do
    assert_no_difference 'User.count' do
      post users_path, params: { user: {
        name:  'Example User',
        email: 'user@example.com',
        password:              '1234567',
        password_confirmation: '1234567'
      } }
    end
    assert_template 'users/new'
    assert_no_difference 'User.count' do
      post users_path, params: { user: {
        name:  'Example User',
        email: 'user@example.com',
        password:              'password',
        password_confirmation: 'password'
      } }
    end
    assert_template 'users/new'
  end

  test 'valid signup information with account activation' do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: {
        name:  'Example User',
        email: 'user@example.com',
        password:              'a-g00d!Xpassword',
        password_confirmation: 'a-g00d!Xpassword'
      } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    # Try to log in before activation.
    log_in_as(user)
    assert_not user_logged_in?
    # Invalid activation token
    get edit_account_activation_path('invalid token')
    assert_not user_logged_in?
    # Valid token, wrong email
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not user_logged_in?
    # Valid activation token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'users/show'
    assert user_logged_in?
  end

  test 'resend account activation for unactivated account' do
    get signup_path
    login_params = { user: {
      name: 'Example User',
      email: 'user@example.com',
      password:              'a-g00d!Xpassword',
      password_confirmation: 'a-g00d!Xpassword'
    } }
    assert_difference 'User.count', 1 do
      post users_path, params: login_params
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_no_difference 'User.count' do
      post users_path, params: login_params
    end
    assert_equal 2, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    # Valid activation token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'users/show'
    assert user_logged_in?
  end

  test 'redirect activated user to login' do
    @user = users(:test_user)
    assert_no_difference 'User.count' do
      post users_path, params: { user: {
        name:  @user.name,
        email: @user.email,
        password:              'password',
        password_confirmation: 'password'
      } }
    end
    assert_not flash.empty?
    follow_redirect!
    assert_template 'sessions/new'
    assert_not user_logged_in?
  end
end
