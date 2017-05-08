# frozen_string_literal: true

class SessionsController < ApplicationController
  include SessionsHelper

  def new
    use_secure_headers_override(:allow_github_form_action)
    store_location
    return unless logged_in?
    flash[:success] = t('sessions.already_logged_in')
    redirect_back_or root_url
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
    redirect_to root_url
    flash[:success] = t('sessions.signed_out')
  end

  private

  # We want to save the forwarding url of a session but
  # still need to counter session fixation,  this does it
  def counter_fixation
    ref_url = session[:forwarding_url] # Save forwarding url
    reset_session # Counter session fixation
    session[:forwarding_url] = ref_url # Reload forwarding url
  end

  def local_login
    user = User.find_by provider: 'local',
                        email: params[:session][:email]
    if user && user.authenticate(params[:session][:password])
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
    log_in user
    redirect_back_or root_url
    flash[:success] = t('sessions.signed_in')
  end

  def local_login_procedure(user)
    if user.activated?
      log_in user
      redirect_back_or root_url
      flash[:success] = t('sessions.signed_in')
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
    else
      flash[:warning] = t('sessions.not_activated')
      redirect_to root_url
    end
  end
end
