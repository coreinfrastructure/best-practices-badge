class SessionsController < ApplicationController
  include SessionsHelper

  def new
  end

  def create
    if params[:provider] == "local"
      user = User.find_by_provider_and_email("local", params[:session][:email].downcase)
      if user && user.authenticate(params[:session][:password])
       log_in user
       redirect_to root_url
        flash[:success] = "Signed in!"
      else
        flash.now[:danger] = 'Invalid email/password combination'
        render 'new'
      end
    else
      auth = request.env["omniauth.auth"]
      user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) || User.create_with_omniauth(auth)
      log_in user
      flash[:notice] = auth 
      flash[:success] = "Signed in!"
      redirect_to root_url
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
    flash[:success] = "Signed out!"
  end


end
