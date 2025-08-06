# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'cgi'

# Security tests for UnsubscribeController
class UnsubscribeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      provider: 'local',
      password: 'valid_password_123',
      activated: true,
      notification_emails: true
    )

    @issued_date = Date.current
    # Generate a valid token for testing
    @valid_token = generate_unsubscribe_token(@user.email, @issued_date)
    @invalid_token = 'a' * 64  # Long enough to pass format validation but cryptographically invalid
  end

  # Test GET request shows the edit form
  test 'should show unsubscribe edit form with parameters' do
    get unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }
    assert_response :success
    assert_select 'form[action=?]', unsubscribe_path(locale: 'en')
    assert_select 'input[name=?][readonly]', 'email'
    assert_select 'input[name=?][readonly]', 'token'
    assert_select 'input[name=?][readonly]', 'issued'
  end

  # Test that locale is optional - URL without locale should redirect to locale-specific URL
  test 'should redirect to locale-specific URL when locale not provided' do
    get unsubscribe_path, params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }
    assert_response :redirect

    # Should redirect to the same URL but with locale added
    redirect_url = @response.location
    assert_includes redirect_url, '/en/unsubscribe'
    assert_includes redirect_url, "email=#{CGI.escape(@user.email)}"
    assert_includes redirect_url, "token=#{@valid_token}"
    assert_includes redirect_url, "issued=#{@issued_date.strftime('%Y-%m-%d')}"
  end

  # Security: Test valid unsubscribe request
  test 'should process valid unsubscribe request' do
    assert @user.notification_emails, 'User should start with notifications enabled'

    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_redirected_to root_path(locale: 'en')

    @user.reload
    assert_not @user.notification_emails, 'User should have notifications disabled after unsubscribe'
  end

  # Security: Test invalid email format (no @ symbol)
  test 'should reject invalid email format' do
    post unsubscribe_path(locale: 'en'), params: {
      email: 'invalid-email-no-at-symbol',
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :bad_request  # Format validation fails early
    assert_match(/invalid.*parameters/i, flash[:error])
  end

  # Security: Test invalid token
  test 'should reject invalid token' do
    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @invalid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :unprocessable_entity
    assert_match(/invalid.*token/i, flash[:error])

    @user.reload
    assert @user.notification_emails, 'User notifications should remain enabled'
  end

  # Security: Test invalid issued date
  test 'should reject invalid issued date' do
    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @valid_token,
      issued: 'invalid-date'
    }

    assert_response :bad_request
    assert_match(/invalid.*parameters/i, flash[:error])
  end

  # Security: Test expired issued date
  test 'should reject expired issued date' do
    old_date = Date.current - 35.days # Older than default 30 days
    old_token = generate_unsubscribe_token(@user.email, old_date)

    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: old_token,
      issued: old_date.strftime('%Y-%m-%d')
    }

    assert_response :unprocessable_entity  # Token verification fails for expired date
    assert_match(/invalid.*token/i, flash[:error])
  end

  # Security: Test future issued date
  test 'should reject future issued date' do
    future_date = Date.current + 2.days
    future_token = generate_unsubscribe_token(@user.email, future_date)

    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: future_token,
      issued: future_date.strftime('%Y-%m-%d')
    }

    assert_response :unprocessable_entity  # Token verification fails for future date
    assert_match(/invalid.*token/i, flash[:error])
  end

  # Security: Test missing parameters
  test 'should reject missing email' do
    post unsubscribe_path(locale: 'en'), params: {
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :bad_request
    assert_match(/missing.*parameters/i, flash[:error])
  end

  test 'should reject missing token' do
    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :bad_request
    assert_match(/missing.*parameters/i, flash[:error])
  end

  test 'should reject missing issued date' do
    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @valid_token
    }

    assert_response :bad_request
    assert_match(/missing.*issued.*date/i, flash[:error])
  end

  # Security: Test email length validation
  test 'should reject overly long email' do
    long_email = 'a' * 250 + '@example.com'

    post unsubscribe_path(locale: 'en'), params: {
      email: long_email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :bad_request
    assert_match(/invalid.*parameters/i, flash[:error])
  end

  # Security: Test token length validation
  test 'should reject overly long token' do
    long_token = 'a' * 200

    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: long_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :bad_request
    assert_match(/invalid.*parameters/i, flash[:error])
  end

  # Security: Test non-existent email with invalid token (must not reveal email)
  test 'should handle non-existent email gracefully' do
    # Use an email that will pass format validation but fail token verification
    # Use a properly formatted but invalid token (64 hex characters)
    invalid_token = 'a' * 64  # Valid format but wrong token
    
    post unsubscribe_path(locale: 'en'), params: {
      email: 'nonexistent@example.com',
      token: invalid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :unprocessable_entity
    assert_match(/invalid.*token/i, flash[:error])
  end

  # Security: Test secure headers are set
  test 'should set secure headers' do
    get unsubscribe_path

    assert_equal 'DENY', response.headers['X-Frame-Options']
    assert_equal 'nosniff', response.headers['X-Content-Type-Options']
    assert_equal '1; mode=block', response.headers['X-XSS-Protection']
  end

  private

  # Helper method to generate unsubscribe token (matches controller logic)
  def generate_unsubscribe_token(email, issued_date = Date.current)
    secret_key = ENV['BADGEAPP_UNSUBSCRIBE_KEY'] || Rails.application.secret_key_base
    date_str = issued_date.is_a?(String) ? issued_date : issued_date.strftime('%Y-%m-%d')
    message = "#{email}:#{date_str}"
    OpenSSL::HMAC.hexdigest('SHA256', secret_key, message)
  end
end
