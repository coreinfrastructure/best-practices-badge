# frozen_string_literal: true
module SessionsHelper
  SESSION_TTL = 48.hours # Automatically log off session if inactive this long

  def log_in(user)
    session[:user_id] = user.id
  end

  # Returns the user corresponding to the remember token cookie
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    store_location
    !current_user.nil?
  end

  # Remembers a user in a persistent session.
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # Forgets a persistent session
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def github_user_projects
    github = Github.new oauth_token: session[:user_token], auto_pagination: true
    github.repos.list.map(&:html_url).reject(&:blank?)
  end

  # Logs out the current user.
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def can_make_changes?
    project_id = params[:id]
    if current_user.nil?
      false
    elsif current_user.projects.exists?(id: project_id)
      true
    elsif current_user.admin?
      true
    elsif current_user.provider == 'github'
      project = Project.find_by(id: project_id)
      return false unless project.repo_url?
      github_user_projects.include? project.repo_url
    else
      false
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Redirects to stored location (or to the default)
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # Stores the URL trying to be accessed
  def store_location
    url = request.url if request.get?
    session[:forwarding_url] = url unless url == login_url
  end

  def session_expired
    return true unless session.key?(:time_last_used)
    session[:time_last_used] < SESSION_TTL.ago.utc
  end

  def validate_session_timestamp
    if logged_in? && session_expired
      reset_session
      session[:current_user] = nil
      redirect_to login_path
    end
  end

  def persist_session_timestamp
    session[:time_last_used] = Time.now.utc if logged_in?
  end
end
