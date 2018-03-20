# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:test_user) # local user
  end

  # rubocop:disable Metrics/BlockLength
  test 'password resets' do
    get '/en/password_resets/new'
    assert_response :success
    assert_includes @response.body, 'Forgot password'

    # Invalid email
    post '/en/password_resets',
         params: { password_reset: { email: '' }, locale: :en }
    assert_not flash.empty?
    # Valid email
    post '/en/password_resets', params: {
      password_reset: { email: @user.email }, locale: :en
    }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # Password reset form
    # user = assigns(:user)
    # Wrong email
    get edit_password_reset_path(id: @user.reset_digest, locale: :en),
        params: { email: '' }
    # TODO: DEBUG: replying with 404, not a redirect.
    assert_redirected_to root_url
    # Inactive user
    @user.toggle!(:activated)
    @user.reload
    get edit_password_reset_path(id: @user.reset_digest, locale: :en),
        params: { email: @user.email }
    assert_redirected_to root_url
    @user.toggle!(:activated)
    # Right email, wrong token
    # get edit_password_reset_path(id: 'wrong_digest_value', locale: :en),
    #    params: { email: @user.email }
    get edit_password_reset_path(id: 'wrong_digest_value', locale: :en),
        params: { email: @user.email }
    assert_redirected_to root_url
    # Right email, right token
    @user.reload
    get edit_password_reset_path(id: @user.reset_digest, locale: :en),
        params: { email: @user.email, id: @user.reset_token }
    assert_select(+'input[name=email][type=hidden][value=?]', @user.email)
    # Invalid password & confirmation
    post password_reset_path(id: @user.reset_digest, locale: :en), params: {
      email: @user.email,
      user: {
        password:              '1235foo',
        password_confirmation: 'bar4567'
      }
    }
    assert_select 'div#error_explanation'
    # Empty password
    patch password_reset_path(id: @user.reset_digest, locale: :en), params: {
      email: @user.email,
      user: {
        password:              '',
        password_confirmation: ''
      }
    }
    assert_select 'div#error_explanation'
    patch password_reset_path(id: 'wrong_reset_digest', locale: :en), params: {
      email: @user.email,
      user: {
        password:              'foo1234!',
        password_confirmation: 'foo1234!'
      }
    }
    assert_select 'div#error_explanation'
    # Valid password & confirmation
    patch password_reset_path(id: @user.reset_digest, locale: :en), params: {
      email: @user.email,
      user: {
        password:              'foo1234!',
        password_confirmation: 'foo1234!'
      }
    }
    assert user_logged_in?
    assert_not flash.empty?
    assert_redirected_to @user
  end
  # rubocop:enable Metrics/BlockLength

  # rubocop:enable Metrics/BlockLength
  test 'expired token' do
    get new_password_reset_path(locale: :en)
    assert_response :success
    assert_includes @response.body, 'Forgot password'

    # post :create, params: {
    # password_reset: { email: @user.email }, locale: :en

    # Request password reset.
    post password_resets_path(locale: :en), params: {
      password_reset: { email: @user.email }
    }
    follow_redirect!
    assert_response :success

    # Simulate the user waiting too long.
    # @user = assigns(:user)
    @user.reload
    @user.update_attribute(:reset_sent_at, 3.hours.ago)

    get edit_password_reset_path(locale: :en, id: @user.reset_digest)
    # patch "/en/password_resets/#{@user.reset_digest}", params: {
    # post password_resets_path(locale: :en, id: @user.reset_digest), params: {
    post "/en/password_resets/#{@user.reset_digest}", params: {
      id: @user.reset_token,
      email: @user.email,
      user: {
        password:              'foo1234',
        password_confirmation: 'bar5678'
      }
    }
    assert_response :redirect
    assert_redirected_to root_path(locale: :en)
  end
end
