# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'addressable/uri'
require 'net/http'

# rubocop:disable Metrics/ClassLength
class ProjectsController < ApplicationController
  include ProjectsHelper
  before_action :set_project, only: %i[edit update destroy show show_json]
  before_action :logged_in?, only: :create
  before_action :can_edit_or_redirect, only: %i[edit update]
  before_action :can_control_or_redirect, only: :destroy
  before_action :set_criteria_level, only: %i[show edit update]

  # Cache with Fastly CDN.  We can't use this header, because logged-in
  # and not-logged-in users see different things (and thus we can't
  # have a cached version that works for everyone):
  # before_action :set_cache_control_headers, only: [:index, :show, :badge]
  # We *can* cache the badge result, and that's what matters anyway.
  before_action :set_cache_control_headers, only: %i[badge show_json]

  helper_method :repo_data

  # These are the only allowed values for "sort" (if a value is provided)
  ALLOWED_SORT =
    %w[
      id name achieved_passing_at badge_percentage_0
      homepage_url repo_url updated_at user_id created_at
    ].freeze

  ALLOWED_STATUS = %w[in_progress passing].freeze

  INTEGER_QUERIES = %i[gteq lteq page].freeze

  TEXT_QUERIES = %i[pq q].freeze

  OTHER_QUERIES = %i[sort sort_direction status ids].freeze

  ALLOWED_QUERY_PARAMS = (
    INTEGER_QUERIES + TEXT_QUERIES + OTHER_QUERIES
  ).freeze

  # GET /projects
  # GET /projects.json
  def index
    validated_url = set_valid_query_url
    if validated_url != request.original_url
      redirect_to validated_url
    else
      retrieve_projects
      sort_projects
      @projects
    end
  end

  # GET /projects/1
  def show; end

  # GET /projects/1.json
  def show_json
    set_surrogate_key_header @project.record_key + '/json'
  end

  BADGE_PROJECT_FIELDS =
    'id, badge_percentage_0, badge_percentage_1, badge_percentage_2'

  def badge
    # Don't use "set_project", but instead specifically find the project
    # ourselves.  That way, we can select *only* the fields we need
    # (there are very few!).  By selecting only what we actually use, we
    # greatly reduce the number of objects created by ActiveRecord, which is
    # important because this common request is supposed to be quick.
    # Note: If the "find" fails this will raise an exception, which
    # will eventually lead (correctly) to a failure report.
    @project = Project.select(BADGE_PROJECT_FIELDS).find(params[:id])
    set_surrogate_key_header @project.record_key + '/badge'
    respond_to do |format|
      format.svg do
        send_data Badge[value_for_badge],
                  type: 'image/svg+xml', disposition: 'inline'
      end
    end
  end

  # GET /projects/new
  def new
    use_secure_headers_override(:allow_github_form_action)
    store_location_and_locale
    @project = Project.new
  end

  # GET /projects/:id/edit(.:format)
  def edit
    return unless @project.notify_for_static_analysis?('0')
    message = t('projects.edit.static_analysis_updated_html')
    flash.now[:danger] = message
  end

  # POST /projects
  # POST /projects.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create
    @project = current_user.projects.build(project_params)
    project_repo_url = @project.repo_url
    if @project.repo_url? && Project.exists?(repo_url: project_repo_url)
      flash[:info] = t('projects.new.project_already_exists')
      return redirect_to Project.find_by(repo_url: project_repo_url)
    end

    # Error out if homepage_url and repo_url are both empty... don't
    # do a save yet.

    @project.homepage_url ||= set_homepage_url
    Chief.new(@project, client_factory).autofill

    respond_to do |format|
      if @project.save
        @project.send_new_project_email
        # @project.purge_all
        flash[:success] = t('projects.new.thanks_adding')
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
    if repo_url_change_allowed?
      old_badge_level = @project.badge_level
      project_params.each do |key, user_value| # mass assign
        @project[key] = user_value
      end
      Chief.new(@project, client_factory).autofill
      respond_to do |format|
        # Was project.update(project_params)
        update_additional_rights
        if @project.save
          successful_update(format, old_badge_level, @criteria_level)
        else
          format.html { render :edit, criteria_level: @criteria_level }
          format.json do
            render json: @project.errors, status: :unprocessable_entity
          end
        end
      end
    else
      flash.now[:danger] = t('projects.edit.repo_url_limits')
      render :edit
    end
  rescue ActiveRecord::StaleObjectError
    message = t('projects.edit.changed_since_html', edit_url: edit_project_url)
    flash.now[:danger] = message
    render :edit, status: :conflict
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # DELETE /projects/1
  # DELETE /projects/1.json
  # rubocop:disable Metrics/MethodLength
  def destroy
    @project.destroy!
    ReportMailer.report_project_deleted(@project, current_user).deliver_now
    purge_cdn_project
    # @project.purge
    # @project.purge_all
    respond_to do |format|
      @project.homepage_url ||= project_find_default_url
      format.html do
        redirect_to projects_url
        flash[:success] = t('projects.delete.done')
      end
      format.json { head :no_content }
    end
  end
  # rubocop:enable Metrics/MethodLength

  # The /feed only displays a small set of the project fields, so only
  # extract the ones we use.  This optimization is worth it because
  # users poll the feed *and* it can include many projects.
  # These are the fields for *projects*; the .recently_updated scope
  # forces loading of user data (where we get the user name/nickname).
  FEED_DISPLAY_FIELDS = 'projects.id as id, projects.name as name, ' \
    'projects.updated_at as updated_at, projects.created_at as created_at, ' \
    'badge_percentage_0, badge_percentage_1, badge_percentage_2, ' \
    'homepage_url, repo_url, description, user_id'

  def feed
    # @projects = Project.select(FEED_DISPLAY_FIELDS).
    #  limit(50).reorder(updated_at: :desc, id: :asc).includes(:user)
    @projects = Project.select(FEED_DISPLAY_FIELDS).recently_updated
    respond_to { |format| format.atom }
  end

  def reminders_summary
    if current_user_is_admin?
      respond_to { |format| format.html }
    else
      flash.now[:danger] = t('admin_only')
      redirect_to '/'
    end
  end

  private

  # Send reminders to users for inactivity. Return array of project ids
  # that were sent reminders (this array may be empty).
  # You should only invoke this in a test environment (where mailers are
  # disabled & the data is forged anyway) or the "real" production site.
  # Do *not* call this on the "master" or "staging" tiers,
  # because we don't want to bother our users.
  # rubocop:disable Metrics/MethodLength
  def self.send_reminders
    projects = Project.projects_to_remind
    unless projects.empty?
      ReportMailer.report_reminder_summary(projects).deliver_now
    end
    projects.each do |inactive_project| # Send actual reminders
      ReportMailer.email_reminder_owner(inactive_project).deliver_now
      # Save while disabling paper_trail's versioning through self.
      # Don't update the updated_at value either, since we interpret that
      # value as being an update of the project badge status information.
      inactive_project.paper_trail.without_versioning do
        inactive_project.last_reminder_at = DateTime.now.utc
        inactive_project.save!(touch: false)
      end
    end
    projects.map(&:id) # Return a list of project ids that were reminded.
  end
  private_class_method :send_reminders
  # rubocop:enable Metrics/MethodLength

  # Send announcement about projects that achieved a badge last month
  # You should only invoke this in a test environment (where mailers are
  # disabled & the data is forged anyway) or the "real" production site.
  # Do *not* call this on the "master" or "staging" tiers,
  # because we don't want to bother our users.
  # rubocop:disable Metrics/MethodLength
  def self.send_monthly_announcement
    consider_today = Time.zone.today
    month = consider_today.prev_month.strftime('%Y-%m')
    last_stat_in_prev_month =
      ProjectStat.last_in_month(consider_today.prev_month)
    last_stat_in_prev_prev_month =
      ProjectStat.last_in_month(consider_today.prev_month.prev_month)
    projects = Project.projects_first_passing_in(consider_today.prev_month)
    ReportMailer.report_monthly_announcement(
      projects, month, last_stat_in_prev_month, last_stat_in_prev_prev_month
    )
                .deliver_now
    projects.map(&:id) # Return a list of project ids that were reminded.
  end
  # rubocop:enble Metrics/MethodLength
  private_class_method :send_monthly_announcement

  def allowed_query?(key, value)
    return false if value.blank?
    return positive_integer?(value) if INTEGER_QUERIES.include?(key.to_sym)
    return TextValidator.new(attributes: %i[query]).text_acceptable?(value) if
      TEXT_QUERIES.include?(key.to_sym)
    allowed_other_query?(key, value)
  end

  def allowed_other_query?(key, value)
    return ALLOWED_SORT.include?(value) if key == 'sort'
    return %w[desc asc].include?(value) if key == 'sort_direction'
    return ALLOWED_STATUS.include?(value) if key == 'status'
    return integer_list?(value) if key == 'ids'
    false
  end

  # Returns true if current_user can edit, else redirect to a different URL
  def can_edit_or_redirect
    return true if can_edit?
    redirect_to root_url
  end

  # Returns true if current_user can control, else redirect to a different URL
  def can_control_or_redirect
    return true if can_control?
    redirect_to root_url
  end

  # Forceably set additional_rights on project "id" given string description
  # Presumes permissions are granted & valid syntax in new_additional_rights
  def update_additional_rights_forced(id, new_additional_rights)
    command = new_additional_rights[0]
    new_list = new_additional_rights[1..-1].split(',').map(&:to_i).uniq.sort
    if command == '-'
      AdditionalRight.where(project_id: id, user_id: new_list).destroy_all
    else # '+'
      new_list.each do |u|
        # Add one-by-one; if a user doesn't exist, we can still do the others
        if User.exists?(id: u)
          AdditionalRight.create!(project_id: id, user_id: u).save!
        end
      end
    end
  end

  VALID_ADD_RIGHTS_CHANGES = /\A[+-](\d+(,\d+)*)+\z/

  # Examine proposed changes to additional rights - if okay, call
  # update_additional_rights_forced to do them.
  # rubocop:disable Metrics/CyclomaticComplexity
  def update_additional_rights
    return unless can_edit? # Double-check - must be able to edit
    return unless params.key?(:project)
    additional_rights_changes = params[:additional_rights_changes]
    return if additional_rights_changes.blank? # Quietly return if blank
    additional_rights_changes = additional_rights_changes.delete(' ')
    # Do input validation.  This would generally only fail during an
    # an attack or weird circumstance, since in the normal non-attack case
    # the input will already have gone through client-side validation.
    return unless VALID_ADD_RIGHTS_CHANGES.match?(additional_rights_changes)
    # *Only* those who *control* the entry can remove additional editors
    return if additional_rights_changes[0] == '-' && !can_control?
    update_additional_rights_forced(@project.id, additional_rights_changes)
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def client_factory
    proc do
      if current_user.nil? || current_user.provider != 'github'
        Octokit::Client.new
      else
        Octokit::Client.new access_token: session[:user_token]
      end
    end
  end

  # Never trust parameters from the scary internet,
  # only allow the white list through.
  def project_params
    params.require(:project).permit(Project::PROJECT_PERMITTED_FIELDS)
  end

  def criteria_level_params
    params.permit([:criteria_level])
  end

  def repo_url_change_allowed?
    return true unless @project.repo_url?
    return true if project_params[:repo_url].nil?
    return true if current_user.admin?
    project_params[:repo_url].split('://', 2)[1] ==
      @project.repo_url.split('://', 2)[1]
  end

  def positive_integer?(value)
    !(value =~ /\A[1-9][0-9]{0,15}\z/).nil?
  end

  def integer_list?(value)
    !(value =~ /\A[1-9][0-9]{0,15}( *, *[1-9][0-9]{0,15}){0,20}\z/).nil?
  end

  # Purge the badge from the CDN (if any)
  def purge_cdn_project
    cdn_badge_key = @project.record_key + '/badge'
    cdn_json_key = @project.record_key + '/json'
    # If we can't authenticate to the CDN, complain but don't crash.
    begin
      FastlyRails.purge_by_key cdn_badge_key
      FastlyRails.purge_by_key cdn_json_key
    rescue StandardError => e
      Rails.logger.error "FAILED TO PURGE #{cdn_badge_key} , #{e.class}: #{e}"
    end
  end

  # rubocop:disable Style/MethodCalledOnDoEndBlock
  def repo_data
    github = Octokit::Client.new access_token: session[:user_token]
    Octokit.auto_paginate = true
    return if github.repos.blank?
    github.repos.map do |repo|
      [repo.full_name, repo.fork, repo.homepage, repo.html_url]
    end.compact
  end
  # rubocop:enable Style/MethodCalledOnDoEndBlock

  HTML_INDEX_FIELDS = 'projects.id, projects.name, description, ' \
    'homepage_url, repo_url, license, user_id, achieved_passing_at, ' \
    'updated_at, badge_percentage_0'

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def retrieve_projects
    @projects = Project.all
    # We had to keep this line the same to satisfy brakeman
    @projects = @projects.public_send params[:status] if
       %w[in_progress passing].include? params[:status]
    @projects = @projects.gteq(params[:gteq]) if params[:gteq].present?
    @projects = @projects.lteq(params[:lteq]) if params[:lteq].present?
    # "Prefix query" - query against *prefix* of a URL or name
    @projects = @projects.text_search(params[:pq]) if params[:pq].present?
    # "Normal query" - text search against URL, name, and description
    # This will NOT match full URLs, but will match partial URLs.
    @projects = @projects.search_for(params[:q]) if params[:q].present?
    if params[:ids].present?
      @projects = @projects.where(
        'id in (?)', params[:ids].split(',').map { |x| Integer(x) }
      )
    end
    @count = @projects.count
    # If we're supplying html (common case), select only needed fields
    format = request&.format&.symbol
    if !format || format == :html
      @projects = @projects.select(HTML_INDEX_FIELDS)
    end
    @projects = @projects.includes(:user).paginate(page: params[:page])
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def set_homepage_url
    return if repo_data.nil?
    # Assign to repo.homepage if it exists, and else repo_url
    repo = repo_data.find { |r| @project.repo_url == r[3] }
    return if repo.nil?
    repo[2].present? ? repo[2] : @project.repo_url
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

  def set_criteria_level
    @criteria_level = criteria_level_params[:criteria_level] || '0'
    @criteria_level = '0' unless @criteria_level.match?(/\A[0-2]\Z/)
  end

  def set_valid_query_url
    # Rewrites /projects?q=&status=failing to /projects?status=failing
    original = request.original_url
    parsed = Addressable::URI.parse(original)
    return original if parsed.query_values.blank?
    valid_queries = parsed.query_values.select { |k, v| allowed_query?(k, v) }
    if valid_queries.blank?
      parsed.omit!(:query) # Removes trailing '?'
    else
      parsed.query_values = valid_queries
    end
    parsed.to_s
  end

  # If a valid "sort" parameter is provided, sort @projects in "sort_direction"
  # rubocop:disable Metrics/AbcSize
  def sort_projects
    # Sort, if there is a requested order (otherwise use default created_at)
    return unless params[:sort].present? && ALLOWED_SORT.include?(params[:sort])
    sort_direction = params[:sort_direction] == 'desc' ? ' desc' : ' asc'
    sort_index = ALLOWED_SORT.index(params[:sort])
    @projects = @projects
                .reorder(ALLOWED_SORT[sort_index] + sort_direction)
                .order('created_at' + sort_direction)
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def successful_update(format, old_badge_level, criteria_level)
    purge_cdn_project
    criteria_level = nil if criteria_level == '0'
    # @project.purge
    format.html do
      if params[:continue]
        flash[:info] = t('projects.edit.successfully_updated')
        redirect_to edit_project_path(
          @project, criteria_level: criteria_level
        ) + url_anchor
      else
        redirect_to project_path(@project, criteria_level: criteria_level),
                    success: t('projects.edit.successfully_updated')
      end
    end
    format.json { render :show, status: :ok, location: @project }
    new_badge_level = @project.badge_level
    return unless new_badge_level != old_badge_level
    # TODO: Eventually deliver_later
    ReportMailer.project_status_change(
      @project, old_badge_level, new_badge_level
    ).deliver_now
    if Project::BADGE_LEVELS.index(new_badge_level) >
       Project::BADGE_LEVELS.index(old_badge_level)
      flash[:success] = t(
        'projects.edit.congrats_new',
        new_badge_level: new_badge_level
      )
      lost_level = false
    else
      flash[:danger] = t('projects.edit.lost_badge')
      lost_level = true
    end
    ReportMailer.email_owner(
      @project, old_badge_level, new_badge_level, lost_level
    ).deliver_now
  end
  # rubocop:enable Metrics/AbcSize

  def url_anchor
    return '#' + params[:continue] unless params[:continue] == 'Save'
    ''
  end

  # This needs to be modified each time you add a new badge level
  # This method gives the percentage value to be passed to the Badge model
  # when getting the svg badge for a project
  def value_for_badge
    return @project.badge_percentage_0 if @project.badge_level == 'in_progress'
    @project.badge_level
  end
end
