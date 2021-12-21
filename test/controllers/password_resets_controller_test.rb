# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:test_user)
  end

  # rubocop:disable Metrics/BlockLength
  test 'password resets' do
    get '/en/password_resets/new'
    assert_includes @response.body, 'Forgot password'
    assert_includes @response.body, 'Email'
    # Invalid email
    post '/en/password_resets', params: { password_reset: { email: '' } }
    assert_not flash.empty?
    assert_includes @response.body, 'Forgot password'
    assert_includes @response.body, 'Email'
    # Valid email
    post '/en/password_resets', params: {
      password_reset: { email: @user.email }
    }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url

    # Password reset form
    user = assigns(:user)

    # Wrong email
    get "/en/password_resets/#{user.reset_token}/edit?email="
    assert_redirected_to root_url

    # Inactive user
    user.toggle!(:activated)
    get "/en/password_resets/#{user.reset_token}/edit?email=#{user.email}"
    assert_redirected_to root_url

    # Right email, wrong token (written here as "wrong_token")
    user.toggle!(:activated)
    get "/en/password_resets/wrong_token/edit?email=#{user.email}"
    assert_redirected_to root_url

    # Right email, right token
    # What's happened here is that the user has received the "reset password"
    # email and clicked on the provided link. That sends a "get" with
    # the provided reset_token *AND* the parameter email=(user.email).
    # It has to be a "get" because the user is clicking on a hyperlink in
    # and email (which causes a "get").
    get "/password_resets/#{user.reset_token}/edit", params: {
      email: user.email
    }
    follow_redirect!
    assert_select(+'input[name=email][type=hidden][value=?]', user.email)

    # No parameters - reject it. This could cause a nil dereference,
    # due to attempting to dereference [:user][:password], and we want to
    # ensure we don't try to do that.
    # This should never happen in normal use, since we don't generate such
    # URLs, so we just redirect to root_url.. test for that.
    put "/en/password_resets/#{user.reset_token}"
    assert_redirected_to root_url(locale: 'en')
    follow_redirect!

    # No "user" value - reject it. This could cause a nil dereference,
    # due to attempting to dereference [:user][:password], and we want to
    # ensure we don't try to do that.
    put "/en/password_resets/#{user.reset_token}", params: {
      email: user.email
    }
    assert @response.body.include?('Password Password can&#39;t be empty')

    # A "user" value without a password - reject it.
    # This could cause a nil dereference,
    # due to attempting to dereference [:user][:password], and we want to
    # ensure we don't try to do that.
    put "/en/password_resets/#{user.reset_token}", params: {
      email: user.email,
      user: {
        junk:              'junk'
      }
    }
    assert @response.body.include?('Password can&#39;t be empty')

    # Unequal password & confirmation should be rejected
    put "/en/password_resets/#{user.reset_token}", params: {
      email: user.email,
      user: {
        password:              '1235foo',
        password_confirmation: 'bar4567'
      }
    }
    assert_select 'div#error_explanation'

    # Empty password - send it back
    patch "/en/password_resets/#{user.reset_token}", params: {
      email: user.email,
      user: {
        password:              '',
        password_confirmation: ''
      }
    }
    assert_select 'div#error_explanation'

    # Valid password & confirmation should actually work
    put "/en/password_resets/#{user.reset_token}", params: {
      email: user.email,
      user: {
        password:              'foo1234!',
        password_confirmation: 'foo1234!'
      }
    }
    assert_not flash.empty?
    assert_not user_logged_in?
    assert_redirected_to login_url(locale: :en)
    # Ensure that password is actually set - reload record and check it!
    assert @user.reload.authenticated?(:password, 'foo1234!')
  end
  # rubocop:enable Metrics/BlockLength

  test 'expired token' do
    get '/en/password_resets/new'
    assert_response :success
    assert_includes @response.body, 'Forgot password'
    assert_includes @response.body, 'Email'

    post '/en/password_resets', params: {
      password_reset: { email: @user.email }
    }
    assert_response :redirect
    follow_redirect!

    # @user = assigns(:user)
    # @user.update_attribute(:reset_sent_at, 3.hours.ago)
    @user.reset_sent_at = 3.hours.ago
    @user.save!
    patch "/en/password_resets/#{@user.reset_token}", params: {
      email: @user.email,
      user: {
        password:              'foo1234',
        password_confirmation: 'foo1234'
      }
    }
    assert_response :redirect
    assert_redirected_to password_resets_path(locale: 'en')
  end
end
