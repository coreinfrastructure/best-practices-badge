# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# TODO: ActionController::TestCase is obsolete. This should switch to using
# ActionDispatch::IntegrationTest and then remove rails-controller-testing.
# See: https://github.com/rails/rails/issues/22496
class PasswordResetsControllerTest < ActionController::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:test_user)
  end

  # rubocop:disable Metrics/BlockLength
  test 'password resets' do
    get :new, params: { locale: :en }
    assert_template 'password_resets/new'
    # Invalid email
    post :create, params: { password_reset: { email: '' }, locale: :en }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # Valid email
    post :create, params: {
      password_reset: { email: @user.email }, locale: :en
    }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # Password reset form
    user = assigns(:user)
    # Wrong email
    get :edit, params: { id: user.reset_token, email: '', locale: :en }
    assert_redirected_to root_url
    # Inactive user
    user.toggle!(:activated)
    get :edit, params: { id: user.reset_token, email: user.email, locale: :en }
    assert_redirected_to root_url
    user.toggle!(:activated)
    # Right email, wrong token
    get :edit, params: { id: 'wrong_token', email: user.email, locale: :en }
    assert_redirected_to root_url
    # Right email, right token
    get :edit, params: { id: user.reset_token, email: user.email, locale: :en }
    assert_template 'password_resets/edit'
    assert_select(+'input[name=email][type=hidden][value=?]', user.email)
    # Invalid password & confirmation
    patch :update, params: {
      id: user.reset_token,
      email: user.email,
      user: {
        password:              '1235foo',
        password_confirmation: 'bar4567'
      },
      locale: :en
    }
    assert_select 'div#error_explanation'
    # Empty password
    patch :update, params: {
      id: user.reset_token,
      email: user.email,
      user: {
        password:              '',
        password_confirmation: ''
      },
      locale: :en
    }
    assert_select 'div#error_explanation'
    # Valid password & confirmation
    patch :update, params: {
      id: user.reset_token,
      email: user.email,
      user: {
        password:              'foo1234!',
        password_confirmation: 'foo1234!'
      },
      locale: :en
    }
    assert_not flash.empty?
    assert_not user_logged_in?
    assert_redirected_to login_url(locale: :en)
  end
  # rubocop:enable Metrics/BlockLength

  # rubocop:enable Metrics/BlockLength
  test 'expired token' do
    get :new
    post :create, params: {
      password_reset: { email: @user.email }, locale: :en
    }

    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch :update, params: {
      id: @user.reset_token,
      email: @user.email,
      user: {
        password:              'foo1234',
        password_confirmation: 'bar5678'
      }
    }
    assert_response :redirect
    assert_redirected_to new_password_reset_path
  end
end
