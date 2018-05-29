# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class SessionsController < ApplicationController
  include SessionsHelper

  # Do *NOT* redirect session creation, that will cause complicated failures
  # because we don't really want the locale.
  skip_before_action :redir_missing_locale, only: :create

  def new
    if logged_in?
      flash[:success] = t('sessions.already_logged_in')
      redirect_to root_url
    else
      use_secure_headers_override(:allow_github_form_action)
      store_location_and_locale
    end
  end

  def create
    counter_fixation # Counter session fixation (but save forwarding url)
    if request.env['omniauth.auth'].present?
      omniauth_login
    elsif params[:session][:provider] == 'local'
      local_login
    else
      flash.now[:danger] = t('sessions.incorrect_login_info')
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    flash[:success] = t('sessions.signed_out')
    redirect_to root_url
  end

  private

  # Perform tasks for a user who just successfully logged in.
  # rubocop: disable Metrics/MethodLength
  def successful_login(user)
    log_in user
    redirect_back_or root_url

    # Report last login time (this can help users detect problems)
    last_login = user.last_login_at
    last_login = t('sessions.no_login_time') if last_login.blank?
    flash[:success] = t('sessions.signed_in', last_login_at: last_login)

    # Record last_login_at time
    user.last_login_at = Time.now.utc
    begin
      user.save!
    rescue OpenSSL::Cipher::CipherError # Keep running if we can't decrypt
      logger.info("CipherError while saving user id #{user.id}")
    end
  end
  # rubocop: enable Metrics/MethodLength

  # We want to save the forwarding url of a session but
  # still need to counter session fixation,  this does it
  def counter_fixation
    ref_url = session[:forwarding_url] # Save forwarding url
    I18n.locale = session[:locale]
    reset_session # Counter session fixation
    session[:forwarding_url] = ref_url # Reload forwarding url
  end

  def local_login
    user = User.find_by provider: 'local',
                        email: params[:session][:email]
    if user&.authenticate(params[:session][:password])
      local_login_procedure(user)
    else
      flash.now[:danger] = t('sessions.invalid_combo')
      render 'new'
    end
  end

  def omniauth_login
    auth = request.env['omniauth.auth']
    user = User.find_by(provider: auth['provider'], uid: auth['uid']) ||
           User.create_with_omniauth(auth)
    session[:user_token] = auth['credentials']['token']
    user.name ||= user.nickname
    successful_login(user)
  end

  def local_login_procedure(user)
    if user.activated?
      successful_login(user)
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
    else
      flash[:warning] = t('sessions.not_activated')
      redirect_to root_url
    end
  end
end
