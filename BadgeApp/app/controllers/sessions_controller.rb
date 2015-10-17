class SessionsController < ApplicationController
  include SessionsHelper

  def new
  end

  def create
    params[:provider] == 'local' ? local_login : omniauth_login
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
    flash[:success] = 'Signed out!'
  end

  private

  # rubocop:disable Metrics/AbcSize
  def local_login
    user = User.where(provider: 'local',
                      email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      log_in user
      redirect_to root_url
      flash[:success] = 'Signed in!'
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def omniauth_login
    auth = request.env['omniauth.auth']
    user = User.where(provider: auth['provider'], uid: auth['uid']) ||
           User.create_with_omniauth(auth)
    session[:user_token] = auth['credentials']['token']
    log_in user
    flash[:success] = 'Signed in!'
    redirect_to root_url
  end
  # rubocop:enable Metrics/AbcSize
end
