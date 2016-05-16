# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :require_admin,  only: %i(index destroy)
  before_action :logged_in_user, only: %i(edit update)
  before_action :correct_user,   only: %i(edit update)
  include SessionsHelper

  def new
    @user = User.new
  end

  def index
    @users = User.all.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    @projects = @user.projects.paginate(page: params[:page])
    if @user == current_user && @user.provider == 'github'
      @edit_projects = Project.where(repo_url: github_user_projects) - @projects
    end
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
    redirect_to @user unless @user.provider == 'local'
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

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = 'User deleted'
    redirect_to users_url
  end

  private

  def user_params
    params.require(:user).permit(
      :provider, :uid, :name, :email, :password,
      :password_confirmation
    )
  end

  def require_admin
    redirect_to root_url unless current_user && current_user.admin?
  end

  # Confirms a logged-in user.
  def logged_in_user
    unless logged_in?
      flash[:danger] = 'Please log in.'
      redirect_to login_url
    end
  end

  # Confirms the correct user.
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless @user == current_user || current_user.admin?
  end
end
