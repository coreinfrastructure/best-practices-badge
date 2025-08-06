# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Controller for handling unsubscribe requests
class UnsubscribeController < ApplicationController
  include SessionsHelper
  include UnsubscribeHelper

  # Security: Enable CSRF protection for form submissions (create action)
  protect_from_forgery with: :exception
  
  # Security: Skip CSRF for unsubscribe actions since users access via email links
  # The unsubscribe process has its own strong security via HMAC token validation
  # which is more secure than CSRF tokens for this use case
  skip_before_action :verify_authenticity_token, only: [:edit, :create]

  # Omit useless unchanged session cookie for performance & privacy
  before_action :omit_unchanged_session_cookie

  # GET /unsubscribe
  # Display the unsubscribe form with email, token, and issued date
  # for confirmation.
  def edit
    return unless validate_unsubscribe_params
    # Set display values for the form (read-only)
    @email = params[:email]
    @issued = params[:issued]  # YYYY-MM-DD
    @token = params[:token]
  end

  # POST /unsubscribe
  # Process the unsubscribe request
  def create
    return unless validate_unsubscribe_params
    begin
      # Security: Use parameterized queries and validate input
      email = params[:email]
      issued = params[:issued]  # YYYY-MM-DD
      token = params[:token]

      # Security: Validate token before checking the database.
      # This gives specific error responses
      unless verify_unsubscribe_token(email, issued, token)
        # Security: Log potential security incident (without PII)
        Rails.logger.info "Invalid unsubscribe token attempt for email domain: #{email.split('@').last}"
        flash[:error] = t('unsubscribe.invalid_token')
        render :edit, status: :unprocessable_entity
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
          render :edit, status: :unprocessable_entity
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
      render :edit, status: :internal_server_error
      return
    rescue StandardError => e
      # Security: Log error without exposing internal details
      Rails.logger.error "Unsubscribe processing error: #{e.class}"
      flash[:error] = t('unsubscribe.error')
      render :edit, status: :internal_server_error
      return
    end

    redirect_to root_path
  end

  private

  # Security: Validate all unsubscribe parameters
  def validate_unsubscribe_params
    email = params[:email]
    issued = params[:issued]
    token = params[:token]

    # Step 1: Check for required parameters
    if email.blank? || issued.blank? || token.blank?
      flash[:error] = t('unsubscribe.missing_parameters')
      render :edit, status: :bad_request
      return false
    end

    # Step 2: Check parameter lengths to prevent DoS attacks
    if email.length > 254 || issued.length > 12 || token.length > 64
      flash[:error] = t('unsubscribe.invalid_parameters')
      render :edit, status: :bad_request
      return false
    end

    # Step 3: Validate individual field formats
    unless valid_email_format?(email) && valid_issued_format?(issued) && valid_token_format?(token)
      flash[:error] = t('unsubscribe.invalid_parameters')
      render :edit, status: :bad_request
      return false
    end

    true
  end
end
