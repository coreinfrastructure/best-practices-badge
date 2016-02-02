class UsersController < ApplicationController
  before_action :require_admin, only: :index
  include SessionsHelper

  def new
    @user = User.new
  end

  def index
    @users = User.all.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    @projects = @user.projects
  end

  def create
    @user = User.new(user_params)
    @user.provider = 'local'
    if @user.save
      @user.send_activation_email
      flash[:info] = 'Please check your email to activate your account.'
      redirect_to root_url
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = 'Profile updated'
      redirect_to @user
    else
      render 'edit'
    end
  end

  private

  def user_params
    params.require(:user).permit(:provider, :uid, :name, :email, :password,
                                 :password_confirmation)
  end

  def require_admin
    redirect_to root_url unless current_user && current_user.admin?
  end
end
