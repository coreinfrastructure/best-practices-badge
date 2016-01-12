module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]

    # @current_user ||= GithubUser.find(session[:user_id]) if session[:user_id]
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    store_location
    !current_user.nil?
  end

  # Logs out the current user.
  def log_out
    session.delete(:user_id)
    @current_user = nil
  end

  def can_make_changes?
    if current_user && current_user.admin?
      true
    elsif logged_in?
      project = current_user.projects.find_by(id: params[:id])
      !project.nil?
    else
      false
    end
  end

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
end
