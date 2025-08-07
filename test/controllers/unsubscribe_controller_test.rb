# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'cgi'

# Security tests for UnsubscribeController
# rubocop:disable Metrics/ClassLength
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
    @invalid_token = 'a' * 64 # Long enough to pass format validation but cryptographically invalid
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
    assert_select 'input[name=?][readonly]', 'display_email'
    assert_select 'input[name=?][readonly]', 'display_token'
    assert_select 'input[name=?][readonly]', 'display_issued'
    # Test that hidden fields contain the actual values for form submission
    assert_select 'input[type=hidden][name=email]'
    assert_select 'input[type=hidden][name=token]'
    assert_select 'input[type=hidden][name=issued]'
  end

  # Security: Test that HTML characters in email are properly escaped to prevent XSS
  test 'should escape HTML characters in email address for XSS prevention' do
    xss_email = '<script>example</script>@example.com'
    valid_token = generate_unsubscribe_token(xss_email, @issued_date)

    get unsubscribe_path(locale: 'en'), params: {
      email: xss_email,
      token: valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :success

    # Verify the response body doesn't contain unescaped script tags
    # This is the key security test - raw HTML should not appear in the response
    assert_not_includes @response.body, '<script>example</script>'

    # Verify that the dangerous content appears escaped in the HTML source
    assert_includes @response.body, '&lt;script&gt;example&lt;/script&gt;'

    # Verify display field exists (Rails automatically escapes the content)
    assert_select 'input[name="display_email"]'

    # Verify hidden field contains the original email for proper form submission
    assert_select 'input[type="hidden"][name="email"]' do |elements|
      hidden_email_value = elements.first['value']
      assert_equal xss_email, hidden_email_value
    end

    # Verify form would submit correctly with all required hidden fields
    assert_select 'form[action=?]', unsubscribe_path(locale: 'en')
    assert_select 'input[type="hidden"][name="token"][value=?]', valid_token
    assert_select 'input[type="hidden"][name="issued"][value=?]', @issued_date.strftime('%Y-%m-%d')

    # Additional test: Verify that form submission would work correctly with XSS email
    # Create a user with the XSS email to test actual unsubscribe functionality
    xss_user = User.create!(
      name: 'XSS Test User',
      email: xss_email,
      provider: 'local',
      password: 'valid_password_123',
      activated: true,
      notification_emails: true
    )

    # Test that POST request with XSS email works correctly (no XSS injection)
    post unsubscribe_path(locale: 'en'), params: {
      email: xss_email,
      token: valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_redirected_to root_path(locale: 'en')
    xss_user.reload
    assert_not xss_user.notification_emails, 'User with XSS email should be unsubscribed'
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

    # First get the form to obtain CSRF token (simulating real user workflow)
    get unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }
    assert_response :success

    # Submit the form with CSRF token
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

    assert_response :bad_request # Format validation fails early
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

    assert_response :unprocessable_entity # Token verification fails for expired date
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

    assert_response :unprocessable_entity # Token verification fails for future date
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
    long_email = ('a' * 250) + '@example.com'

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
    invalid_token = 'a' * 64 # Valid format but wrong token

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

  # Test zero updated count scenario - when no matching users found with notification_emails=true
  test 'should handle no matching accounts to unsubscribe' do
    # Create a user with notification_emails already disabled
    user_already_unsubscribed = User.create!(
      name: 'Already Unsubscribed User',
      email: 'already_unsubscribed@example.com',
      provider: 'local',
      password: 'valid_password_123',
      activated: true,
      notification_emails: false
    )

    # Generate token for the already unsubscribed user
    token = generate_unsubscribe_token(user_already_unsubscribed.email, @issued_date)

    post unsubscribe_path(locale: 'en'), params: {
      email: user_already_unsubscribed.email,
      token: token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :unprocessable_entity
    assert_match(/no.*matching.*accounts/i, flash[:error])

    # Verify user state remains unchanged
    user_already_unsubscribed.reload
    assert_not user_already_unsubscribed.notification_emails, 'User should remain unsubscribed'
  end

  # Test no matching users scenario with different approach - user with different email
  test 'should handle unsubscribe request for non-existent email' do
    non_existent_email = 'nonexistent@example.com'
    token = generate_unsubscribe_token(non_existent_email, @issued_date)

    post unsubscribe_path(locale: 'en'), params: {
      email: non_existent_email,
      token: token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :unprocessable_entity
    assert_match(/no.*matching.*accounts/i, flash[:error])
  end

  # Integration test: Full workflow with CSRF protection enabled
  # Tests the complete user journey: click email URL -> view form -> submit form -> unsubscribe
  test 'should complete full unsubscribe workflow with CSRF protection' do
    assert @user.notification_emails, 'User should start with notifications enabled'

    # Step 1: User clicks URL from email (GET request - no CSRF needed)
    get unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :success
    assert_select 'form[action=?]', unsubscribe_path(locale: 'en')

    # Verify the form includes CSRF token (Rails automatically adds it when CSRF is enabled)
    assert_select 'input[name="authenticity_token"]', 1

    # Step 2: Extract CSRF token from the rendered form
    # In a real browser, this would be automatically included in form submission
    csrf_token = css_select('input[name="authenticity_token"]').first['value']
    assert_not_nil csrf_token, 'CSRF token should be present in the form'

    # Step 3: User submits the form (POST request - CSRF protection applies)
    post unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d'),
      authenticity_token: csrf_token
    }

    # Step 4: Verify successful unsubscribe
    assert_redirected_to root_path(locale: 'en')

    @user.reload
    assert_not @user.notification_emails, 'User should be unsubscribed after form submission'
  end

  # Test that CSRF protection is properly configured for the create action
  test 'should have CSRF protection enabled for create action' do
    # Check that the controller includes the forgery protection module
    assert UnsubscribeController.included_modules.include?(ActionController::RequestForgeryProtection),
           'Controller should include CSRF protection module'

    # Create controller instance to test the skip_before_action behavior
    controller = UnsubscribeController.new

    # Test that edit action would skip CSRF (this verifies our configuration)
    controller.action_name = 'edit'
    edit_filters = controller.class._process_action_callbacks
                             .select { |cb| cb.kind == :before && cb.filter == :verify_authenticity_token }

    # Should have the skip configuration in place
    assert edit_filters.any?, 'Should have CSRF-related before_action callbacks configured'

    # The key test: verify that create action is NOT in the skip list
    # by checking that the controller source includes the correct skip_before_action
    controller_source = File.read(Rails.root.join('app/controllers/unsubscribe_controller.rb'))
    assert_match(/skip_before_action.*:verify_authenticity_token.*only.*\[:edit\]/, controller_source,
                 'Controller should skip CSRF only for edit action, not create')
  end

  # Test that the form includes CSRF token for proper form submission
  test 'should include CSRF token in unsubscribe form' do
    get unsubscribe_path(locale: 'en'), params: {
      email: @user.email,
      token: @valid_token,
      issued: @issued_date.strftime('%Y-%m-%d')
    }

    assert_response :success
    # Verify that the form includes authenticity_token field
    assert_select 'input[name="authenticity_token"]', 1, 'Form should include CSRF token'

    # Verify the token has a value
    csrf_token = css_select('input[name="authenticity_token"]').first['value']
    assert_not_nil csrf_token, 'CSRF token should have a value'
    assert csrf_token.length > 10, 'CSRF token should be a meaningful length'
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
# rubocop:enable Metrics/ClassLength
