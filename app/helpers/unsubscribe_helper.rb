# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Helper module for unsubscribe functionality
module UnsubscribeHelper
  # Security: Generate secure unsubscribe token with email and issued date
  # This method generates tokens using only email and date, no database access
  #
  # @param email [String] The email address to generate the token for
  # @param issued_date [Date/String] The date when the email was issued
  # @return [String] A secure HMAC-based token
  def generate_unsubscribe_token(email, issued_date)
    return nil if email.blank? || issued_date.nil?
    
    # Security: Use dedicated unsubscribe secret key from environment
    secret_key = ENV['BADGEAPP_UNSUBSCRIBE_KEY'] || Rails.application.secret_key_base
    
    # Security: Use HMAC with secret key for token generation
    # Include issued date in the message for time-based validation
    date_str = issued_date.is_a?(String) ? issued_date : issued_date.strftime('%Y-%m-%d')
    message = "#{email}:#{date_str}"
    OpenSSL::HMAC.hexdigest('SHA256', secret_key, message)
  end

  # Security: Generate new unsubscribe token with current date
  # This method determines current date and generates token with issued date
  #
  # @param email [String] The email address to generate the token for
  # @return [Array] Array containing [issued_date_string, token]
  def generate_new_unsubscribe_token(email)
    return [nil, nil] if email.blank?
    
    # Get current date in YYYY-MM-DD format
    issued_date = Date.current.strftime('%Y-%m-%d')
    
    # Generate token using email and current date
    token = generate_unsubscribe_token(email, issued_date)
    
    [issued_date, token]
  end

  # Security: Generate secure unsubscribe URL with issued date
  # This method creates a complete URL that can be used in emails
  #
  # @param user [User] The user to generate the URL for
  # @param issued_date [Date] The date when the email was issued (default: today)
  # @param locale [String] Optional locale for the URL (default: current locale)
  # @return [String] A complete unsubscribe URL with token and issued date
  def generate_unsubscribe_url(user, issued_date = Date.current, locale: I18n.locale)
    return nil if user.nil? || issued_date.nil?
    
    # Security: Validate issued date first
    unless valid_issued_date?(issued_date)
      Rails.logger.warn "Invalid issued date for unsubscribe URL: #{issued_date}"
      return nil
    end
    
    token = generate_unsubscribe_token(user.email, issued_date)
    return nil if token.nil?
    
    date_str = issued_date.is_a?(String) ? issued_date : issued_date.strftime('%Y-%m-%d')
    
    # Security: Generate URL with proper locale and parameters
    # Use Rails URL helpers for security and proper encoding
    url_for(
      controller: 'unsubscribe',
      action: 'show',
      locale: locale,
      email: user.email,
      token: token,
      issued: date_str,
      only_path: false,
      protocol: Rails.application.config.force_ssl ? 'https' : 'http'
    )
  end

  # Security: Verify unsubscribe token with time-based validation
  # This method uses constant-time comparison and NO database access
  #
  # @param email [String] The email address to verify the token for
  # @param token [String] The token to verify
  # @param issued_date [Date/String] The issued date from the request
  # @return [Boolean] True if the token is valid and within time window
  def verify_unsubscribe_token(email, token, issued_date)
    return false if email.blank? || token.blank? || issued_date.nil?
    
    # Security: Validate issued date format and range
    unless valid_issued_date?(issued_date)
      return false
    end
    
    # Security: Check if token is within valid time window
    unless token_within_valid_period?(issued_date)
      return false
    end
    
    # Security: Generate expected token for comparison (no database access)
    expected_token = generate_unsubscribe_token(email, issued_date)
    return false if expected_token.nil?
    
    # Security: Use constant-time comparison to prevent timing attacks
    ActiveSupport::SecurityUtils.secure_compare(expected_token, token)
  end

  # Security: Validate issued date format and reasonableness
  # @param issued_date [Date/String] The date to validate
  # @return [Boolean] True if date is valid and within acceptable range
  def valid_issued_date?(issued_date)
    return false if issued_date.blank?
    
    begin
      # Convert string to Date if needed
      date = issued_date.is_a?(String) ? Date.parse(issued_date) : issued_date
      
      # Security: Check date format is valid YYYY-MM-DD
      date_str = date.strftime('%Y-%m-%d')
      return false unless date_str.match?(/\A\d{4,}-\d{2}-\d{2}\z/)
      
      # Security: Check date is not in future (with small tolerance for clock skew)
      return false if date > Date.current + 1.day
      
      # Security: Check date is not too far in past (prevents replay attacks)
      max_age_days = (ENV['BADGEAPP_UNSUBSCRIBE_DAYS'] || '30').to_i
      return false if date < Date.current - max_age_days.days
      
      true
    rescue ArgumentError, TypeError
      false
    end
  end

  # Security: Check if token is within valid time period
  # @param issued_date [Date/String] The issued date to check
  # @return [Boolean] True if within valid period
  def token_within_valid_period?(issued_date)
    return false if issued_date.blank?
    
    begin
      date = issued_date.is_a?(String) ? Date.parse(issued_date) : issued_date
      max_age_days = (ENV['BADGEAPP_UNSUBSCRIBE_DAYS'] || '30').to_i
      
      # Security: Token is valid if issued date is within the allowed window
      date >= Date.current - max_age_days.days && date <= Date.current
    rescue ArgumentError, TypeError
      false
    end
  end

  # Security: Check if a user can be unsubscribed
  # This method verifies user state and subscription status
  #
  # @param user [User] The user to check
  # @return [Boolean] True if the user can be unsubscribed, false otherwise
  def can_unsubscribe?(user)
    return false if user.nil?
    return false if user.blocked?
    
    # Only allow unsubscribe for users who have notifications enabled
    user.notification_emails?
  end

  # Security: Log unsubscribe action safely (without PII)
  # This method logs unsubscribe actions for audit purposes
  #
  # @param user [User] The user who unsubscribed
  # @param request [ActionDispatch::Request] The request object for IP logging
  # @param success [Boolean] Whether the unsubscribe was successful
  def log_unsubscribe_action(user, request, success: true)
    return if user.nil? || request.nil?
    
    # Security: Log without exposing PII
    Rails.logger.info(
      "Unsubscribe #{success ? 'success' : 'failure'}: " \
      "user_id=#{user.id}, " \
      "ip=#{request.remote_ip}, " \
      "user_agent=#{request.user_agent&.truncate(100)}"
    )
  end

  # Helper: Parse and validate issued date from request parameters
  # @param issued_param [String] The issued date parameter from request
  # @return [Date, nil] Parsed date or nil if invalid
  def parse_issued_date(issued_param)
    return nil if issued_param.blank?
    
    begin
      # Security: Strict date parsing for YYYY-MM-DD format
      return nil unless issued_param.match?(/^\d{4}-\d{2}-\d{2}$/)
      
      date = Date.parse(issued_param)
      return date if valid_issued_date?(date)
    rescue ArgumentError
      # Invalid date format
    end
    
    nil
  end

  # Helper: Obfuscate email for display (privacy)
  # @param email [String] The email to obfuscate
  # @return [String] Obfuscated email
  def obfuscate_email(email)
    return '' if email.blank?
    
    parts = email.split('@')
    return email if parts.length != 2
    
    local, domain = parts
    return email if domain.nil?
    
    # Show first and last character of local part, hide middle
    if local.length <= 2
      obfuscated_local = '*' * local.length
    else
      obfuscated_local = local[0] + '*' * (local.length - 2) + local[-1]
    end
    
    "#{obfuscated_local}@#{domain}"
  end
end
