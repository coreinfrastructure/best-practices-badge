class UsersController < ApplicationController
  include SessionsHelper

  def new
    @user = User.new
  end

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)
    @user.provider = "local"
    if @user.save
      log_in @user
      flash[:success] = "Welcome to the Open Source Software Badging Program!"
      redirect_to @user
    else
     render 'new'
    end
  end

  private

    def user_params
      params.require(:user).permit(:provider, :uid, :name, :email, :password,
                                   :password_confirmation)
    end

end
