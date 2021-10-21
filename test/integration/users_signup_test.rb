# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop: disable Metrics/ClassLength
class UsersSignupTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test 'invalid signup information' do
    VCR.use_cassette('invalid_signup_information') do
      assert_no_difference 'User.count' do
        post users_path, params: {
          user: {
            name:  '',
            email: 'user@invalid',
            password:              'foo',
            password_confirmation: 'bar'
          },
          locale: :en
        }
      end
    end
    assert_template 'users/new'
  end

  # rubocop: disable Metrics/BlockLength
  test 'reject bad passwords' do
    VCR.use_cassette('reject_bad_passwords') do
      assert_no_difference 'User.count' do
        post users_path, params: {
          user: {
            name:  'Example User',
            email: 'user@example.com',
            password:              '1234567',
            password_confirmation: '1234567'
          },
          locale: :en
        }
      end
      assert_template 'users/new'
      assert_no_difference 'User.count' do
        post users_path, params: {
          user: {
            name:  'Example User',
            email: 'user@example.com',
            password:              'password',
            password_confirmation: 'password'
          },
          locale: :en
        }
      end
      assert_template 'users/new'
    end
  end
  # rubocop: enable Metrics/BlockLength

  # rubocop: disable Metrics/BlockLength
  test 'valid signup information with account activation' do
    VCR.use_cassette('valid_signup_information_with_account_activation') do
      get signup_path
      assert_difference 'User.count', 1 do
        post users_path, params: {
          user: {
            name:  'Example User',
            email: 'user@example.com',
            password:              'a-g00d!Xpassword',
            password_confirmation: 'a-g00d!Xpassword'
          },
          locale: :en
        }
      end
      assert_equal 1, ActionMailer::Base.deliveries.size
      user = assigns(:user)
      assert_not user.activated?
      # Try to log in before activation.
      log_in_as(user)
      assert_not user_logged_in?
      # Invalid activation token
      get edit_account_activation_path('invalid token', locale: :en)
      assert_not user_logged_in?
      # Valid token, wrong email
      get edit_account_activation_path(
        user.activation_token, email: 'wrong', locale: :en
      )
      assert_not user.reload.activated?
      assert_not user_logged_in?
      assert_not user.login_allowed_now?
      # Valid activation token
      get edit_account_activation_path(
        user.activation_token, email: user.email, locale: :en
      )
      assert user.reload.activated?
      follow_redirect!
      assert_template 'sessions/new'
      assert_not user_logged_in?
      assert_not user.login_allowed_now?
      # Try to log in as activated local user *before* cooloff time
      log_in_as(user, password: 'a-g00d!Xpassword')
      assert_template 'sessions/new'
      assert_not user_logged_in?
      assert_not user.login_allowed_now?
      # Try to log in as activated local user *after* cooloff time
      user.can_login_starting_at = Time.zone.now - 1.day.seconds
      user.save!
      assert user.login_allowed_now?
      log_in_as(user, password: 'a-g00d!Xpassword')
      assert user_logged_in?
    end
  end
  # rubocop: enable Metrics/BlockLength

  # rubocop: disable Metrics/BlockLength
  test 'resend account activation for unactivated account' do
    VCR.use_cassette('resend_account_activation_for_unactivated_account') do
      get signup_path
      login_params = {
        user: {
          name: 'Example User',
                email: 'user@example.com',
                password:              'a-g00d!Xpassword',
                password_confirmation: 'a-g00d!Xpassword'
        }
      }
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
      get edit_account_activation_path(user.activation_token,
                                       email: user.email)
      assert user.reload.activated?
      follow_redirect!
      assert_template 'sessions/new'
      assert_not user_logged_in?
    end
  end
  # rubocop: enable Metrics/BlockLength

  test 'redirect activated user to login' do
    @user = users(:test_user)
    assert_no_difference 'User.count' do
      post users_path, params: {
        user: {
          name:  @user.name,
          email: @user.email,
          password:              'password',
          password_confirmation: 'password'
        },
        locale: :en
      }
    end
    assert_not flash.empty?
    follow_redirect!
    assert_template 'sessions/new'
    assert_not user_logged_in?
  end
end
# rubocop: enable Metrics/ClassLength
