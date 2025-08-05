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

  # GET /unsubscribe
  # Display the unsubscribe form with email, token, and issued date
  # for confirmation.
  def show
    validate_unsubscribe_params
    # Set display values for the form (read-only)
    @email = params[:email]
    @token = params[:token]
    @issued_date = params[:issued]&.strftime('%Y-%m-%d')
  end

  # POST /unsubscribe
  # Process the unsubscribe request
  def create
    validate_unsubscribe_params
    begin
      # Security: Use parameterized queries and validate input
      email = params[:email]
      issued_date = params[:issued]&.strftime('%Y-%m-%d')
      token = params[:token]

      # Security: FIRST check that token is valid.
      # We *only* check if there's an email once we've verified that we
      # sent the authentication token in the first place.
      if verify_unsubscribe_token(user, token, issued_date)

        # Find user by email using ActiveRecord's safe parameter binding
        # Security: Use safe database queries with parameterized statements
        # Note: it's okay to reveal if the user exists at this point. That's
        # because the requestor already knows this, as proven by
        # having a valid unsubscribe message token from us
        # *with* the email address, authentication token, and issue date.
        user = User.where('LOWER(email) = LOWER(?)', email).first

        if user.nil?
          flash[:notice] = t('unsubscribe.failure')
        else
          # Use database transaction for atomicity
          ActiveRecord::Base.transaction do
            # Update user's subscription preferences
            user.update!(
              notification_emails: false,
              updated_at: Time.current
            )

            # Security: Log the unsubscribe action (without PII)
            log_unsubscribe_action(user, request, success: true)
            flash[:notice] = t('unsubscribe.success')
          end
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

  # Check email validity. This is a loose check, because
  # increasingly people are using UTF-8 usernames and internationalized
  # domain names. We don't need to check carefully, because we only use it
  # to match against the database of existing email addresses.
  # We could be pickier, e.g.:
  # /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
  EMAIL_REGEX = /\A[^@]+.*+\z/

  # Security: Validate email format with strict regex
  def valid_email_format?(email)
    return false if email.blank?
    return false if email.length > 254 # RFC 5321 limit

    email.match?(EMAIL_REGEX)
  end

  ISSUED_REGEX = /\A[0-9]{4,6}+-[0-9]{2}-[0-9]{2}\z/

  # Security: Verify unsubscribe token using constant-time comparison
  def valid_issued_format?(issued)
    return false if issued.blank?
    return false if issued.length < 10 || issued.length > 12

    issued.match?(ISSUED_REGEX)
  end

  # Security: Validate token format and length
  def valid_token_format?(token)
    return false if token.blank?
    return false if token.length < 32 || token.length > 256

    # Security: Ensure token contains only legal characters
    token.match?(/\A[a-zA-Z0-9]+\z/)
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

    # Security: First check parameter lengths to counter DoS
    if email.length > 254 || token.length > 256 || issued.length > 12 ||
       !valid_email_format?(email) || !valid_token_format?(token) ||
       !valid_issued_format?(issued)
      flash[:error] = t('unsubscribe.invalid_parameters')
      render :show, status: :bad_request
      return
    end
  end
end
