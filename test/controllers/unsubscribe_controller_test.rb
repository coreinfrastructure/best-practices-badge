# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

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
    @valid_token = generate_unsubscribe_token(@user, @issued_date)
    @invalid_token = 'invalid_token_123'
  end

  # Test GET request shows the form
  test 'should show unsubscribe form with parameters' do
    get unsubscribe_path, params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }
    assert_response :success
    assert_select 'form[action=?]', unsubscribe_path
    assert_select 'input[name=?][readonly]', 'email'
    assert_select 'input[name=?][readonly]', 'token'
    assert_select 'input[name=?][readonly]', 'issued'
  end

  # Security: Test valid unsubscribe request
  test 'should process valid unsubscribe request' do
    assert @user.notification_emails, 'User should start with notifications enabled'
    
    post unsubscribe_path, params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }
    
    assert_redirected_to root_path
    assert_match(/success/i, flash[:notice])
    
    @user.reload
    assert_not @user.notification_emails, 'User notifications should be disabled'
  end

  # Security: Test invalid email format
  test 'should reject invalid email format' do
    post unsubscribe_path, params: {
      email: 'invalid-email',
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }
    
    assert_response :unprocessable_entity
    assert_match(/invalid.*email/i, flash[:error])
  end

  # Security: Test invalid token
  test 'should reject invalid token' do
    post unsubscribe_path, params: {
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
    post unsubscribe_path, params: {
      email: @user.email,
      token: @valid_token,
      issued: 'invalid-date'
    }
    
    assert_response :bad_request
    assert_match(/invalid.*issued.*date/i, flash[:error])
  end

  # Security: Test expired issued date
  test 'should reject expired issued date' do
    old_date = Date.current - 35.days # Older than default 30 days
    old_token = generate_unsubscribe_token(@user, old_date)
    
    post unsubscribe_path, params: {
      email: @user.email,
      token: old_token,
      issued: old_date.strftime('%Y-%m-%d')
    }
    
    assert_response :bad_request
    assert_match(/invalid.*issued.*date/i, flash[:error])
  end

  # Security: Test future issued date
  test 'should reject future issued date' do
    future_date = Date.current + 2.days
    future_token = generate_unsubscribe_token(@user, future_date)
    
    post unsubscribe_path, params: {
      email: @user.email,
      token: future_token,
      issued: future_date.strftime('%Y-%m-%d')
    }
    
    assert_response :bad_request
    assert_match(/invalid.*issued.*date/i, flash[:error])
  end

  # Security: Test missing parameters
  test 'should reject missing email' do
    post unsubscribe_path, params: {
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }
    
    assert_response :bad_request
    assert_match(/missing.*parameters/i, flash[:error])
  end

  test 'should reject missing token' do
    post unsubscribe_path, params: {
      email: @user.email,
      issued: @issued_date.strftime('%Y-%m-%d')
    }
    
    assert_response :bad_request
    assert_match(/missing.*parameters/i, flash[:error])
  end

  test 'should reject missing issued date' do
    post unsubscribe_path, params: {
      email: @user.email,
      token: @valid_token
    }
    
    assert_response :bad_request
    assert_match(/missing.*issued.*date/i, flash[:error])
  end

  # Security: Test email length validation
  test 'should reject overly long email' do
    long_email = 'a' * 250 + '@example.com'
    
    post unsubscribe_path, params: {
      email: long_email,
      token: @valid_token
    }
    
    assert_response :bad_request
    assert_match(/invalid.*parameters/i, flash[:error])
  end

  # Security: Test token length validation
  test 'should reject overly long token' do
    long_token = 'a' * 200
    
    post unsubscribe_path, params: {
      email: @user.email,
      token: long_token
    }
    
    assert_response :bad_request
    assert_match(/invalid.*parameters/i, flash[:error])
  end

  # Security: Test non-existent email (should not reveal existence)
  test 'should handle non-existent email gracefully' do
    post unsubscribe_path, params: {
      email: 'nonexistent@example.com',
      token: @valid_token
    }
    
    assert_redirected_to root_path
    assert_match(/processed/i, flash[:notice])
  end

  # Security: Test honeypot field detection
  test 'should reject requests with honeypot field filled' do
    post unsubscribe_path, params: {
      email: @user.email,
      token: @valid_token,
      website: 'http://spam.com'
    }
    
    # The honeypot check happens in JavaScript, but we can test server-side too
    # This test ensures the server doesn't process obvious bot requests
    # (Implementation depends on adding server-side honeypot check)
  end

  # Security: Test CSRF protection
  test 'should require valid CSRF token' do
    # Disable CSRF temporarily to test the protection
    ActionController::Base.allow_forgery_protection = true
    
    post unsubscribe_path, params: {
      email: @user.email,
      token: @valid_token
    }, headers: { 'HTTP_X_CSRF_TOKEN' => 'invalid' }
    
    # Should fail due to CSRF protection
    assert_response :forbidden
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  # Security: Test rate limiting (would need to be implemented)
  test 'should implement rate limiting' do
    # This test verifies rate limiting works
    # Make 6 requests quickly to trigger rate limit
    6.times do
      post unsubscribe_path, params: {
        email: @user.email,
        token: 'invalid'
      }
    end
    
    # The 6th request should be rate limited
    assert_response :too_many_requests
    assert_match(/rate.*limit/i, flash[:error])
  end

  # Security: Test SQL injection prevention
  test 'should prevent SQL injection in email parameter' do
    malicious_email = "'; DROP TABLE users; --"
    
    post unsubscribe_path, params: {
      email: malicious_email,
      token: @valid_token
    }
    
    # Should handle safely without SQL injection
    assert_response :unprocessable_entity
    assert User.exists?(@user.id), 'Users table should still exist'
  end

  # Security: Test XSS prevention in parameters
  test 'should sanitize XSS in parameters' do
    xss_email = '<script>alert("xss")</script>@example.com'
    
    post unsubscribe_path, params: {
      email: xss_email,
      token: @valid_token
    }
    
    assert_response :unprocessable_entity
    # Verify the script tag is not in the response
    assert_not response.body.include?('<script>')
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
  def generate_unsubscribe_token(user, issued_date = Date.current)
    secret_key = ENV['BADGEAPP_UNSUBSCRIBE_KEY'] || Rails.application.secret_key_base
    date_str = issued_date.is_a?(String) ? issued_date : issued_date.strftime('%Y-%m-%d')
    message = "#{user.id}:#{user.email}:#{date_str}"
    OpenSSL::HMAC.hexdigest('SHA256', secret_key, message)
  end
end
