# frozen_string_literal: true
require 'addressable/uri'
require 'net/http'

# rubocop:disable Metrics/ClassLength
class ProjectsController < ApplicationController
  include ProjectsHelper
  before_action :set_project, only: %i(edit update destroy show badge)
  before_action :logged_in?, only: :create
  before_action :change_authorized, only: %i(destroy edit update)

  # Cache with Fastly CDN.  We can't use this header, because logged-in
  # and not-logged-in users see different things (and thus we can't
  # have a cached version that works for everyone):
  # before_action :set_cache_control_headers, only: [:index, :show, :badge]
  # We *can* cache the badge result, and that's what matters anyway.
  before_action :set_cache_control_headers, only: [:badge]

  helper_method :repo_data

  # These are the only allowed values for "sort" (if a value is provided)
  ALLOWED_SORT =
    %w(
      id name achieved_passing_at badge_percentage
      homepage_url repo_url updated_at user_id created_at
    ).freeze

  # If a valid "sort" parameter is provided, sort @projects in "sort_direction"
  # rubocop:disable Metrics/AbcSize
  def sort_projects
    # Sort, if there is a requested order (otherwise use default created_at)
    return unless params[:sort].present? && ALLOWED_SORT.include?(params[:sort])
    sort_direction =
      if params[:sort_direction] == 'desc' # descending
        ' desc'
      else
        ' asc' # default is ascending
      end
    @projects = @projects
                .reorder(params[:sort] + sort_direction)
                .order('created_at' + sort_direction)
  end
  # rubocop:enable Metrics/AbcSize

  # GET /projects
  # GET /projects.json
  # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  def index
    remove_empty_query_params
    @projects = Project.all
    @projects = @projects.send params[:status] if
      %w(in_progress passing).include? params[:status]
    @projects = @projects.gteq(params[:gteq]) if params[:gteq].present?
    @projects = @projects.lteq(params[:lteq]) if params[:lteq].present?
    # "Prefix query" - query against *prefix* of a URL or name
    @projects = @projects.text_search(params[:pq]) if params[:pq].present?
    # "Normal query" - text search against URL, name, and description
    # This will NOT match full URLs, but will match partial URLs.
    @projects = @projects.search_for(params[:q]) if params[:q].present?
    @count = @projects.count
    @projects = @projects.includes(:user).paginate(page: params[:page])
    sort_projects
    @projects
  end
  # rubocop:enable Metrics/AbcSize,Metrics/MethodLength

  # GET /projects/1
  # GET /projects/1.json
  def show
  end

  def badge
    set_surrogate_key_header @project.record_key + '/badge'
    respond_to do |format|
      format.svg do
        send_data Badge[@project.badge_percentage],
                  type: 'image/svg+xml', disposition: 'inline'
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

    # Error out if homepage_url and repo_url are both empty... don't
    # do a save yet.

    @project.homepage_url ||= set_homepage_url
    Chief.new(@project, client_factory).autofill

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
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def update
    old_badge_level = Project.find(params[:id]).badge_level
    Chief.new(@project, client_factory).autofill
    respond_to do |format|
      if @project.update(project_params)
        successful_update(format, old_badge_level)
      else
        format.html { render :edit }
        format.json do
          render json: @project.errors, status: :unprocessable_entity
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def client_factory
    proc do
      if current_user.nil? || current_user.provider != 'github'
        Octokit::Client.new
      else
        Octokit::Client.new access_token: session[:user_token]
      end
    end
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def successful_update(format, old_badge_level)
    purge_cdn_badge
    # @project.purge
    format.html do
      redirect_to @project, success: 'Project was successfully updated.'
    end
    format.json { render :show, status: :ok, location: @project }
    new_badge_level = @project.badge_level
    if new_badge_level != old_badge_level # TODO: Eventually deliver_later
      ReportMailer.project_status_change(
        @project, old_badge_level, new_badge_level
      ).deliver_now
      if new_badge_level == 'passing'
        flash[:success] = 'CONGRATULATIONS on earning a badge!' \
          ' Please show your badge status on your project page (see the' \
          ' "how to embed it" text just below if you don\'t' \
          ' know how to do that).'
        ReportMailer.email_owner(@project, new_badge_level).deliver_now
      elsif new_badge_level == 'in_progress'
        flash[:danger] = 'Project no longer has a badge.'
        ReportMailer.email_owner(@project, new_badge_level).deliver_now
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    purge_cdn_badge
    # @project.purge
    # @project.purge_all
    respond_to do |format|
      @project.homepage_url ||= project_find_default_url
      format.html do
        redirect_to projects_url
        flash[:success] = 'Project was successfully deleted.'
      end
      format.json { head :no_content }
    end
  end

  def feed
    @projects = Project.recently_updated
    respond_to { |format| format.atom }
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

  # Send reminders to users for inactivity. Return array of project ids
  # that were sent reminders (this array may be empty).
  # You should only invoke this in a test environment (where mailers are
  # disabled & the data is forged anyway) or the "real" production site.
  # Do *not* call this on the "master" or "staging" tiers,
  # because we don't want to bother our users.
  def self.send_reminders
    projects = Project.projects_to_remind
    ReportMailer.report_reminder_summary(projects).deliver_now # Tell LF
    projects.each do |inactive_project| # Send actual reminders
      ReportMailer.email_reminder_owner(inactive_project).deliver_now
      # Save while disabling paper_trail's versioning through self.
      inactive_project.paper_trail.without_versioning do
        # project.last_reminder_at = DateTime.now.utc
        inactive_project.update_attributes! last_reminder_at: DateTime.now.utc
      end
    end
    projects.map(&:id) # Return a list of project ids that were reminded.
  end

  private

  def set_homepage_url
    # Assign to repo.homepage if it exists, and else repo_url
    repo = repo_data.find { |r| @project.repo_url == r[3] }
    return nil if repo.nil?
    repo[2].present? ? check_https(repo[2]) : @project.repo_url
  end

  def check_https(url)
    # Prepend http:// or https:// if not present in url
    return url if url.start_with? 'http'
    https_url = 'https://' + url
    http_url = 'http://' + url
    request = Net::HTTP.get URI(https_url)
  rescue
    request.nil? ? http_url : https_url
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

  # Never trust parameters from the scary internet,
  # only allow the white list through.
  def project_params
    if @project && repo_url_disabled?(@project)
      params.require(:project).permit(Project::PROJECT_PERMITTED_FIELDS)
    else
      params.require(:project).permit(
        :repo_url,
        Project::PROJECT_PERMITTED_FIELDS
      )
    end
  end

  def change_authorized
    return true if can_make_changes?
    redirect_to root_url
  end

  # Purge the badge from the CDN (if any)
  def purge_cdn_badge
    cdn_badge_key = @project.record_key + '/badge'
    # If we can't authenticate to the CDN, complain but don't crash.
    begin
      FastlyRails.purge_by_key cdn_badge_key
    rescue StandardError => e
      Rails.logger.error "FAILED TO PURGE #{cdn_badge_key} , #{e.class}: #{e}"
    end
  end

  def remove_empty_query_params
    # Rewrites /projects?q=&status=failing to /projects?status=failing
    original = request.original_url
    parsed = Addressable::URI.parse(original)
    return unless parsed.query_values.present?
    queries_with_values = parsed.query_values.reject { |_k, v| v.blank? }
    if queries_with_values.blank?
      parsed.omit!(:query) # Removes trailing '?'
    else
      parsed.query_values = queries_with_values
    end
    redirect_to parsed.to_s unless parsed.to_s == original
  end
end
