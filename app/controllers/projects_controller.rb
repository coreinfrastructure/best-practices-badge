# rubocop:disable Metrics/ClassLength
class ProjectsController < ApplicationController
  before_action :set_project, only: [:edit, :update, :destroy, :show, :badge]
  before_action :logged_in?, only: :create
  before_action :change_authorized, only: [:destroy, :edit, :update]

  # Cache with Fastly CDN.  We can't use this header, because logged-in
  # and not-logged-in users see different things (and thus we can't
  # have a cached version that works for everyone):
  # before_action :set_cache_control_headers, only: [:index, :show, :badge]
  # We *can* cache the badge result, and that's what matters anyway.
  before_action :set_cache_control_headers, only: [:badge]

  helper_method :repo_data

  # GET /projects
  # GET /projects.json
  def index
    @search = Project.all.includes(:user).ransack(params[:q])
    @projects = @search.result
                       .paginate(page: params[:page]) # per_page: 5
    # set_surrogate_key_header 'projects', @projects.map(&:record_key)
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    # set_surrogate_key_header @project.record_key
  end

  def badge
    set_surrogate_key_header @project.record_key + '/badge'
    respond_to do |format|
      status = Project.badge_achieved?(@project) ? 'passing' : 'failing'
      format.svg do
        send_file Rails.application.assets["badge-#{status}.svg"].pathname,
                  disposition: 'inline'
      end
    end
  end

  # GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/:id/edit(.:format)
  def edit
  end

  # POST /projects
  # POST /projects.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create
    @project = current_user.projects.build(project_params)
    project_repo_url = @project.repo_url
    if @project.repo_url? && Project.exists?(repo_url: project_repo_url)
      flash[:info] = 'This project already exists!'
      return redirect_to Project.find_by(repo_url: project_repo_url)
    end

    # Error out if project_homepage_url and repo_url are both empty... don't
    # do a save yet.

    @project.project_homepage_url ||= set_homepage_url
    Chief.new(@project).autofill

    respond_to do |format|
      if @project.save
        # @project.purge_all
        flash[:success] = "Thanks for adding the Project!   Please fill out
                           the rest of the information to get the Badge."
        format.html { redirect_to edit_project_path(@project) }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json do
          render json: @project.errors, status: :unprocessable_entity
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  # rubocop:disable Metrics/MethodLength
  def update
    old_badge_status = Project.badge_achieved_id?(params[:id])
    Chief.new(@project).autofill
    respond_to do |format|
      if @project.update(project_params)
        successful_update(format, old_badge_status)
      else
        format.html { render :edit }
        format.json do
          render json: @project.errors, status: :unprocessable_entity
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def successful_update(format, old_badge_status)
    FastlyRails.purge_by_key(@project.record_key + '/badge')
    # @project.purge
    format.html do
      redirect_to @project, success: 'Project was successfully updated.'
    end
    format.json { render :show, status: :ok, location: @project }
    new_badge_status = Project.badge_achieved?(@project)
    if new_badge_status != old_badge_status # TODO: Eventually deliver_later
      ReportMailer.project_status_change(
        @project, old_badge_status, new_badge_status).deliver_now
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    FastlyRails.purge_by_key @project.record_key + '/badge'
    # @project.purge
    # @project.purge_all
    respond_to do |format|
      @project.project_homepage_url ||= project_find_default_url
      format.html do
        redirect_to projects_url
        flash[:success] = 'Project was successfully deleted.'
      end
      format.json { head :no_content }
    end
  end

  def repo_data
    github = Github.new oauth_token: session[:user_token], auto_pagination: true
    github.repos.list.map do |repo|
      if repo.blank?
        nil
      else
        [repo.full_name, repo.fork, repo.homepage, repo.html_url]
      end
    end.compact
  end

  private

  def set_homepage_url
    # Assign to repo.homepage if it exists, and else repo_url
    repo = repo_data.find { |r| @project.repo_url == r[3] }
    return nil if repo.nil?
    repo[2].present? ? repo[2] : @project.repo_url
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

  # Never trust parameters from the scary internet,
  # only allow the white list through.
  def project_params
    params.require(:project).permit(Project::PROJECT_PERMITTED_FIELDS_ARRAY)
  end

  def change_authorized
    return true if can_make_changes?
    redirect_to root_url
  end
end
