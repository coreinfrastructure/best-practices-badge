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
    date_str = normalize_date_string(issued_date)
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
    generate_unsubscribe_url_internal(user, issued_date, locale)
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
      date = parse_date(issued_date)

      # Security: Check date format is valid YYYY-MM-DD
      date_str = date.strftime('%Y-%m-%d')
      return false unless valid_date_format?(date_str)

      # Security: Check date is not in future (with small tolerance for clock skew)
      return false if date > Date.current + 1.day

      # Security: Check date is not too far in past (prevents replay attacks)
      max_age_days = max_token_age_days
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
      date = parse_date(issued_date)
      max_age_days = max_token_age_days

      # Security: Token is valid if issued date is within the allowed window
      date >= Date.current - max_age_days.days && date <= Date.current
    rescue ArgumentError, TypeError
      false
    end
  end

  # Security: Validate email format  
  # @param email [String] Email to validate
  # @return [Boolean] True if email format is valid
  def valid_email_format?(email)
    return false if email.blank?
    return false if email.length > 254 # RFC 5321 limit

    # Use very loose email validation - just check for @ symbol
    # Rely on view escaping for XSS protection rather than restricting email formats
    email.include?('@')
  end  # Security: Validate token format and length
  # @param token [String] Token to validate
  # @return [Boolean] True if token format is valid
  def valid_token_format?(token)
    return false if token.blank?

    # HMAC-SHA256 produces 64-character hex strings
    return false if token.length != 64

    # Security: Ensure token contains only hex characters
    token.match?(/\A[a-f0-9]{64}\z/)
  end

  # Security: Validate issued date format
  # @param issued [String] Issued date string to validate
  # @return [Boolean] True if format is valid
  def valid_issued_format?(issued)
    return false if issued.blank?
    return false if issued.length < 10 || issued.length > 12

    # Strict YYYY-MM-DD format
    issued.match?(/\A\d{4}-\d{2}-\d{2}\z/)
  end

  private

  # Internal URL generation method to eliminate duplication
  # @param user [User] The user to generate the URL for
  # @param issued_date [Date] The date when the email was issued
  # @param locale [String, nil] Optional locale for the URL
  # @return [String, nil] Complete unsubscribe URL or nil if invalid
  def generate_unsubscribe_url_internal(user, issued_date, locale)
    return nil if user.nil? || issued_date.nil?

    # Security: Validate issued date first
    unless valid_issued_date?(issued_date)
      Rails.logger.warn "Invalid issued date for unsubscribe URL: #{issued_date}"
      return nil
    end

    token = generate_unsubscribe_token(user.email, issued_date)
    return nil if token.nil?

    date_str = normalize_date_string(issued_date)

    # Security: Generate URL with proper parameters
    # Use Rails URL helpers for security and proper encoding
    url_params = {
      controller: 'unsubscribe',
      action: 'show',
      email: user.email,
      token: token,
      issued: date_str,
      only_path: false,
      protocol: Rails.application.config.force_ssl ? 'https' : 'http'
    }

    # Add locale if provided
    url_params[:locale] = locale if locale

    url_for(url_params)
  end

  # Normalize date to YYYY-MM-DD string format
  # @param date [Date/String] Date to normalize
  # @return [String] Date in YYYY-MM-DD format
  def normalize_date_string(date)
    date.is_a?(String) ? date : date.strftime('%Y-%m-%d')
  end

  # Parse date from string or return date as-is
  # @param date_input [Date/String] Date to parse
  # @return [Date] Parsed date
  def parse_date(date_input)
    date_input.is_a?(String) ? Date.parse(date_input) : date_input
  end

  # Get maximum token age in days from environment
  # @return [Integer] Maximum age in days
  def max_token_age_days
    (ENV['BADGEAPP_UNSUBSCRIBE_DAYS'] || '30').to_i
  end

  # Validate date string format (YYYY-MM-DD)
  # @param date_str [String] Date string to validate
  # @return [Boolean] True if format is valid
  def valid_date_format?(date_str)
    date_str.match?(/\A\d{4,}-\d{2}-\d{2}\z/)
  end
end
