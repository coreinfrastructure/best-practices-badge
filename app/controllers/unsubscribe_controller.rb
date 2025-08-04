# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Controller for handling unsubscribe requests
class UnsubscribeController < ApplicationController
  include SessionsHelper
  include UnsubscribeHelper

  # Security: Enable CSRF protection for all actions
  protect_from_forgery with: :exception

  # Omit useless unchanged session cookie for performance & privacy
  before_action :omit_unchanged_session_cookie

  # Security: Rate limiting to prevent abuse
  before_action :check_rate_limit, only: [:create]
  
  # Security: Validate and sanitize parameters
  before_action :validate_unsubscribe_params, only: [:create, :show]
  
  # Security: Parse and validate issued date early
  before_action :parse_issued_date, only: [:create, :show]

  # GET /unsubscribe
  # Display the unsubscribe form with email, token, and issued date
  def show
    # Security: Set secure headers for the response
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    
    # Security: Generate a secure nonce for CSP if needed
    @nonce = SecureRandom.base64(32)
    
    # Set display values for the form (read-only)
    @email = sanitize_input(params[:email])
    @token = sanitize_input(params[:token])
    @issued_date = @parsed_issued_date&.strftime('%Y-%m-%d')
    
    render :show
  end

  # POST /unsubscribe
  # Process the unsubscribe request
  def create
    begin
      # Security: Use parameterized queries and validate input
      email = sanitized_params[:email]
      token = sanitized_params[:token]
      issued_date = @parsed_issued_date
      
      # Security: Validate email format using a strict regex
      unless valid_email_format?(email)
        flash[:error] = t('unsubscribe.invalid_email')
        render :show, status: :unprocessable_entity
        return
      end

      # Security: Validate token format and length
      unless valid_token_format?(token)
        flash[:error] = t('unsubscribe.invalid_token')
        render :show, status: :unprocessable_entity
        return
      end

      # Security: Validate issued date was parsed successfully
      unless issued_date
        flash[:error] = t('unsubscribe.invalid_issued_date')
        render :show, status: :unprocessable_entity
        return
      end

      # Security: Use safe database queries with parameterized statements
      # Find user by email using ActiveRecord's safe parameter binding
      user = User.where('LOWER(email) = LOWER(?)', email).first

      if user.nil?
        # Security: Don't reveal if email exists or not (timing-safe comparison)
        sleep(rand(0.1..0.3)) # Add random delay to prevent timing attacks
        flash[:notice] = t('unsubscribe.processed')
        redirect_to root_path
        return
      end

      # Security: Verify unsubscribe token with issued date using constant-time comparison
      if verify_unsubscribe_token(user, token, issued_date)
        # Security: Use database transaction for atomicity
        ActiveRecord::Base.transaction do
          # Update user's subscription preferences
          user.update!(
            notification_emails: false,
            updated_at: Time.current
          )
          
          # Security: Log the unsubscribe action (without PII)
          log_unsubscribe_action(user, request, success: true)
        end
        
        flash[:notice] = t('unsubscribe.success')
      else
        # Security: Log potential security incident (without PII)
        log_unsubscribe_action(user, request, success: false)
        flash[:error] = t('unsubscribe.invalid_token')
        render :show, status: :unprocessable_entity
        return
      end

    rescue ActiveRecord::RecordInvalid => e
      # Security: Log error without exposing internal details
      Rails.logger.error "Unsubscribe database error: #{e.class}"
      flash[:error] = t('unsubscribe.error')
      render :show, status: :internal_server_error
      return
    rescue StandardError => e
      # Security: Log error without exposing internal details
      Rails.logger.error "Unsubscribe processing error: #{e.class}"
      flash[:error] = t('unsubscribe.error')
      render :show, status: :internal_server_error
      return
    end

    redirect_to root_path
  end

  private

  # Security: Strong parameter filtering and validation
  def sanitized_params
    params.permit(:email, :token, :issued).tap do |permitted|
      # Security: Sanitize input to prevent XSS
      permitted[:email] = sanitize_input(permitted[:email])
      permitted[:token] = sanitize_input(permitted[:token])
      permitted[:issued] = sanitize_input(permitted[:issued])
    end
  end

  # Security: Parse and validate issued date from parameters
  def parse_issued_date
    issued_param = params[:issued]
    
    if issued_param.blank?
      flash[:error] = t('unsubscribe.missing_issued_date')
      if action_name == 'show'
        render :show, status: :bad_request
      else
        render :show, status: :bad_request
      end
      return
    end
    
    @parsed_issued_date = parse_issued_date(issued_param)
    
    unless @parsed_issued_date
      flash[:error] = t('unsubscribe.invalid_issued_date')
      if action_name == 'show'
        render :show, status: :bad_request
      else
        render :show, status: :bad_request
      end
      return
    end
  end

  # Security: Validate email format with strict regex
  def valid_email_format?(email)
    return false if email.blank?
    return false if email.length > 254 # RFC 5321 limit
    
    # Security: Use a strict email validation regex
    email_regex = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
    email.match?(email_regex)
  end

  # Security: Validate token format and length
  def valid_token_format?(token)
    return false if token.blank?
    return false if token.length < 32 || token.length > 128
    
    # Security: Ensure token contains only safe characters
    token.match?(/\A[a-zA-Z0-9\-_=]+\z/)
  end

  # Security: Sanitize input to prevent XSS
  def sanitize_input(value)
    return nil if value.blank?
    
    # Security: Strip dangerous characters and normalize
    ActionController::Base.helpers.sanitize(
      value.to_s.strip,
      tags: [], # No HTML tags allowed
      attributes: [] # No attributes allowed
    )
  end

  # Security: Verify unsubscribe token using constant-time comparison
  def valid_unsubscribe_token?(user, token)
    verify_unsubscribe_token(user, token, @parsed_issued_date)
  end

  # Security: Generate secure unsubscribe token
  def generate_unsubscribe_token(user)
    # Delegate to helper method with issued date
    super(user, @parsed_issued_date)
  end

  # Security: Rate limiting to prevent abuse
  def check_rate_limit
    # Security: Implement rate limiting based on IP address
    client_ip = request.remote_ip
    cache_key = "unsubscribe_rate_limit:#{client_ip}"
    
    current_attempts = Rails.cache.read(cache_key) || 0
    
    if current_attempts >= 5 # Max 5 attempts per hour
      Rails.logger.warn "Rate limit exceeded for unsubscribe from IP: #{client_ip}"
      flash[:error] = t('unsubscribe.rate_limit_exceeded')
      render :show, status: :too_many_requests
      return
    end
    
    # Security: Increment attempt counter with expiration
    Rails.cache.write(cache_key, current_attempts + 1, expires_in: 1.hour)
  end

  # Security: Validate all unsubscribe parameters
  def validate_unsubscribe_params
    email = params[:email]
    token = params[:token]
    issued = params[:issued]
    
    # Security: Check for required parameters
    if email.blank? || token.blank? || issued.blank?
      flash[:error] = t('unsubscribe.missing_parameters')
      render :show, status: :bad_request
      return
    end
    
    # Security: Check parameter lengths to prevent DoS
    if email.length > 254 || token.length > 128 || issued.length > 10
      flash[:error] = t('unsubscribe.invalid_parameters')
      render :show, status: :bad_request
      return
    end
  end
end
