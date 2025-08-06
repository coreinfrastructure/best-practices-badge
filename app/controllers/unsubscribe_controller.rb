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
    return unless validate_unsubscribe_params
    # Set display values for the form (read-only)
    @email = params[:email]
    @token = params[:token]
    @issued_date = params[:issued]
  end

  # POST /unsubscribe
  # Process the unsubscribe request
  def create
    return unless validate_unsubscribe_params
    begin
      # Security: Use parameterized queries and validate input
      email = params[:email]
      issued_date = params[:issued]  # Already in YYYY-MM-DD format
      token = params[:token]

      # Security: Validate token FIRST - this gives specific error responses
      unless verify_unsubscribe_token(email, token, issued_date)
        # Security: Log potential security incident (without PII)
        Rails.logger.warn "Invalid unsubscribe token attempt for email domain: #{email.split('@').last}"
        flash[:error] = t('unsubscribe.invalid_token')
        render :show, status: :unprocessable_entity
        return
      end

      # Use database transaction for atomicity
      ActiveRecord::Base.transaction do
        # Update ALL users with exact matching email address (case-sensitive)
        # Security: Use safe database queries with parameterized statements
        updated_count = User.where(email: email, notification_emails: true)
                           .update_all(notification_emails: false, updated_at: Time.current)

        if updated_count.zero?
          flash[:error] = t('unsubscribe.no_matching_accounts')
          render :show, status: :unprocessable_entity
          return
        end

        # Security: Log the unsubscribe action (without PII)
        Rails.logger.info "Unsubscribe success: #{updated_count} accounts updated for domain: #{email.split('@').last}"
        flash[:notice] = t('unsubscribe.success', count: updated_count)
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

  # Security: Validate all unsubscribe parameters
  def validate_unsubscribe_params
    email = params[:email]
    token = params[:token]
    issued = params[:issued]

    # Security: Check for required parameters
    if email.blank? || token.blank? || issued.blank?
      flash[:error] = t('unsubscribe.missing_parameters')
      render :show, status: :bad_request
      return false
    end

    # Security: First check parameter lengths to counter DoS
    if email.length > 254 || token.length > 256 || issued.length > 12 ||
       !valid_email_format?(email) || !valid_token_format?(token) ||
       !valid_issued_format?(issued)
      flash[:error] = t('unsubscribe.invalid_parameters')
      render :show, status: :bad_request
      return false
    end

    true
  end
end
