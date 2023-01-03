# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'addressable/uri'
require 'net/http'

# rubocop:disable Metrics/ClassLength
class ProjectsController < ApplicationController
  include ProjectsHelper

  # The 'badge' action is special and does NOT take a locale.
  skip_before_action :redir_missing_locale, only: :badge

  before_action :set_project,
                only: %i[edit update delete_form destroy show show_json]
  before_action :require_logged_in, only: :create
  before_action :can_edit_else_redirect, only: %i[edit update]
  before_action :can_control_else_redirect, only: %i[destroy delete_form]
  before_action :require_adequate_deletion_rationale, only: :destroy
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
      id name tiered_percentage
      achieved_passing_at achieved_silver_at achieved_gold_at
      homepage_url repo_url updated_at user_id created_at
    ].freeze

  ALLOWED_STATUS = %w[in_progress passing].freeze

  INTEGER_QUERIES = %i[gteq lteq page].freeze

  TEXT_QUERIES = %i[pq q].freeze

  OTHER_QUERIES = %i[sort sort_direction status ids url].freeze

  ALLOWED_QUERY_PARAMS = (
    INTEGER_QUERIES + TEXT_QUERIES + OTHER_QUERIES
  ).freeze

  # Used to validate deletion rationale.
  AT_LEAST_15_NON_WHITESPACE = /\A\s*(\S\s*){15}.*/.freeze

  # as= values, which redirect to alternative views
  ALLOWED_AS = %w[badge entry].freeze

  # "Normal case" index after projects are retrieved
  def show_normal_index
    select_data_subset
    sort_projects
    @projects
  end

  # GET /projects
  # GET /projects.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/BlockNesting
  def index
    validated_url = set_valid_query_url
    if validated_url == request.original_url
      retrieve_projects

      # Omit useless unchanged session cookie for performance & privacy
      # We *must not* set error messages in the flash area after this,
      # because flashes are stored in the session.
      omit_unchanged_session_cookie

      if params[:as] == 'badge' # Redirect to badge view
        # We redirect, instead of responding directly with the answer, because
        # then the requesting browser and CDN will handle repeat requests.
        # We only retrieve ids, because we don't need any other data.
        # Also, we just need to know if the search is unique, not the
        # full list of matches, so we limit() ourselves to two responses.
        ids = @projects.limit(2).ids
        redir_to_badge(ids)
      elsif params[:as] == 'entry' # Redirect to badge view
        ids = @projects.limit(2).ids
        if ids.size == 1
          suffix = request&.format&.symbol == :json ? '.json' : ''
          redirect_to "/#{locale}/projects/#{ids[0]}#{suffix}",
                      status: :moved_permanently
        else
          # If there's not one entry, show the project index instead.
          show_normal_index
        end
      else
        show_normal_index
      end
    else
      redirect_to validated_url
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/BlockNesting

  # Redirect to the *single* relevant badge entry, if there is one.
  # We take a *list* of ids, because if there's >1, it's not unique.
  # rubocop:disable Metrics/MethodLength
  def redir_to_badge(id_list)
    count = id_list.size
    if count.zero?
      render(
        template: 'static_pages/error_404',
        formats: [:html], layout: false, status: :not_found # 404
      )
    elsif count > 1 # There is no unique badge
      render(
        template: 'static_pages/error_409',
        formats: [:html], layout: false, status: :conflict # 409
      )
    else
      suffix = request&.format&.symbol == :json ? '.json' : ''
      # In *theory* this hasn't "moved permanently", because someone *could*
      # create a new matching badge entry *and* delete the old badge entry.
      # They could also make a query ambiguous.
      # But in practice, ids are as "permanent" as anything on the web gets.
      # If we say it's moved permanently, then browsers & caches &
      # search engines will do the right thing, so that's the status used.
      redirect_to "/projects/#{id_list[0]}/badge#{suffix}",
                  status: :moved_permanently
    end
  end
  # rubocop:disable Metrics/MethodLength

  # GET /projects/1
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def show
    # Omit useless unchanged session cookie for performance & privacy
    # We *must not* set error messages in the flash area after this,
    # because flashes are stored in the session.
    omit_unchanged_session_cookie

    # Fix malformed queries of form "/en/projects/188?criteria_level,2"
    # These produce parsed.query_values of {"criteria_level,2"=>nil}
    # They end up as weird special keys, so this is the easy way to detect them
    # We fix these malformed queries to increase the chance that a user
    # will find the intended data.
    parsed = Addressable::URI.parse(request.original_url)
    if parsed&.query_values&.include?('criteria_level,2')
      redirect_to project_path(@project, criteria_level: 2),
                  status: :moved_permanently
    elsif parsed&.query_values&.include?('criteria_level,1')
      redirect_to project_path(@project, criteria_level: 1),
                  status: :moved_permanently
    elsif parsed&.query_values&.include?('criteria_level,0')
      redirect_to project_path(@project, criteria_level: 0),
                  status: :moved_permanently
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # GET /projects/1.json
  def show_json
    # Tell CDN the surrogate key so we can quickly erase it later
    set_surrogate_key_header @project.record_key
  end

  # GET /projects/:id/delete_form(.:format)
  def delete_form; end

  BADGE_PROJECT_FIELDS =
    'id, name, updated_at, tiered_percentage, ' \
    'badge_percentage_0, badge_percentage_1, badge_percentage_2'

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def badge
    # Don't use "set_project", but instead specifically find the project
    # ourselves.  That way, we select *only* the fields we need
    # (there are very few!).  By selecting only what we actually use, we
    # greatly reduce the number of objects created by ActiveRecord, which is
    # important because this common request is supposed to be quick.
    # Note: If the "find" fails this will raise an exception, which
    # will eventually lead (correctly) to a failure report.
    @project = Project.select(BADGE_PROJECT_FIELDS).find(params[:id])

    # Tell CDN the surrogate key so we can quickly erase it later
    set_surrogate_key_header @project.record_key

    # Never send session cookie
    request.session_options[:skip] = true

    respond_to do |format|
      format.svg do
        send_data Badge[@project.badge_value],
                  type: 'image/svg+xml', disposition: 'inline'
      end
      format.json do
        format.json { render :badge, status: :ok, location: @project }
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # GET /projects/new
  def new
    use_secure_headers_override(:allow_github_form_action)
    store_location_and_locale
    @project = Project.new
  end

  # GET /projects/:id/edit(.:format)
  def edit
    return unless @project.notify_for_static_analysis?('0')

    message = t('.static_analysis_updated_html')
    flash.now[:danger] = message
  end

  # POST /projects
  # POST /projects.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # Try to create a new project entry.
  # Clean up repo_url and homepage_url specially to make it easier to
  # identify duplicates.
  def create
    @project = current_user.projects.build(project_params)
    project_repo_url = clean_url(@project.repo_url)
    @project.repo_url = project_repo_url
    if project_repo_url.present?
      if Project.exists?(repo_url: project_repo_url)
        flash[:info] = t('projects.new.project_already_exists')
        return redirect_to Project.find_by(repo_url: project_repo_url)
      end
    end

    # Error out if homepage_url and repo_url are both empty... don't
    # do a save yet.

    @project.homepage_url ||= set_homepage_url
    Chief.new(@project, client_factory).autofill
    if @project.homepage_url
      @project.homepage_url = clean_url(@project.homepage_url)
    end

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
  # rubocop:disable Metrics/PerceivedComplexity
  def update
    if repo_url_change_allowed?
      # Send CDN purge early, to give it time to distribute purge request
      purge_cdn_project
      old_badge_level = @project.badge_level
      project_params.each do |key, user_value| # mass assign
        @project[key] = user_value
      end
      Chief.new(@project, client_factory).autofill

      @project.repo_url_updated_at = Time.now.utc if @project.repo_url_changed?

      # Force cleanup of homepage_url so unintentional duplicates
      # are easier to find.
      if @project[:homepage_url].present?
        @project[:homepage_url] = clean_url(@project[:homepage_url])
      end

      respond_to do |format|
        update_additional_rights
        # The project model's "save" method updates the various
        # percentage values (via a `before_save`), so we can depend on them
        # after saving.
        if @project.save
          successful_update(format, old_badge_level, @criteria_level)
          # Also send CDN purge last, to increase likelihood of being purged
          purge_cdn_project
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
  # rubocop:enable Metrics/PerceivedComplexity

  # DELETE /projects/1
  # DELETE /projects/1.json
  # Form parameter "deletion_rationale" has the user-provided rationale.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def destroy
    @project.destroy!
    ReportMailer.report_project_deleted(
      @project, current_user, params[:deletion_rationale]
    ).deliver_now
    # @project.purge
    # @project.purge_all
    respond_to do |format|
      @project.homepage_url ||= project_find_default_url
      format.html do
        redirect_to projects_path
        flash.now[:success] = t('projects.delete.done')
      end
      format.json { head :no_content }
    end
    purge_cdn_project
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # The /feed only displays a small set of the project fields, so only
  # extract the ones we use.  This optimization is worth it because
  # users poll the feed *and* it can include many projects.
  # These are the fields for *projects*; the .recently_updated scope
  # forces loading of user data (where we get the user name/nickname).
  FEED_DISPLAY_FIELDS = 'projects.id as id, projects.name as name, ' \
                        'projects.updated_at as updated_at, ' \
                        'projects.created_at as created_at, ' \
                        'tiered_percentage, ' \
                        'badge_percentage_0, badge_percentage_1, ' \
                        'badge_percentage_2, ' \
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
      flash[:danger] = t('admin_only')
      redirect_to root_path
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
      # Save datetime while disabling paper_trail's versioning through self.
      # Use "touch: false" to also prevent changing the updated_at value;
      # we interpret the updated_at value as being an update of the
      # project badge status information by users and admins.
      PaperTrail.request(enabled: false) do
        inactive_project.last_reminder_at = Time.now.utc
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
    prev_month = consider_today.prev_month
    month_display = prev_month.strftime('%Y-%m')
    last_stat_in_prev_month = ProjectStat.last_in_month(prev_month)
    last_stat_in_prev_prev_month =
      ProjectStat.last_in_month(prev_month.prev_month)
    projects = Array.new(Project::LEVEL_IDS.size)
    Project::LEVEL_ID_NUMBERS.each do |level|
      projects[level] = Project.projects_first_in(level, prev_month)
    end
    ReportMailer.report_monthly_announcement(
      projects, month_display, last_stat_in_prev_month,
      last_stat_in_prev_prev_month
    )
                .deliver_now
    # To simplify certain tests, return list of project ids newly passing
    projects[0].ids
  end
  # rubocop:enable Metrics/MethodLength
  private_class_method :send_monthly_announcement

  def allowed_query?(key, value)
    return false if value.blank?
    return positive_integer?(value) if INTEGER_QUERIES.include?(key.to_sym)
    return TextValidator.new(attributes: %i[query]).text_acceptable?(value) if
      TEXT_QUERIES.include?(key.to_sym)

    allowed_other_query?(key, value)
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def allowed_other_query?(key, value)
    return ALLOWED_SORT.include?(value) if key == 'sort'
    return %w[desc asc].include?(value) if key == 'sort_direction'
    return ALLOWED_STATUS.include?(value) if key == 'status'
    return integer_list?(value) if key == 'ids'
    return ALLOWED_AS.include?(value) if key == 'as'
    return true if key == 'url'

    false
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # Returns true if current_user can edit, else redirect to a different URL
  def can_edit_else_redirect
    return true if can_edit?

    redirect_to root_path
  end

  # Returns true if current_user can control, else redirect to a different URL
  def can_control_else_redirect
    return true if can_control?

    redirect_to root_path
  end

  # rubocop:disable Metrics/AbcSize
  def require_adequate_deletion_rationale
    return true if current_user&.admin?

    deletion_rationale = params[:deletion_rationale]
    deletion_rationale = '' if deletion_rationale.blank? # E.g., null
    if deletion_rationale.length < 20
      flash[:danger] = t('projects.delete_form.too_short')
      redirect_to delete_form_project_path(@project)
    elsif !AT_LEAST_15_NON_WHITESPACE.match?(deletion_rationale)
      flash[:danger] = t('projects.delete_form.more_non_whitespace')
      redirect_to delete_form_project_path(@project)
    end
  end
  # rubocop:enable Metrics/AbcSize

  # Forceably set additional_rights on project "id" given string description
  # Presumes permissions are granted & valid syntax in new_additional_rights
  # rubocop:disable Metrics/MethodLength
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
  # rubocop:enable Metrics/MethodLength

  VALID_ADD_RIGHTS_CHANGES = /\A[+-](\d+(,\d+)*)+\z/.freeze

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

  # Return an extracted URL without its scheme ('http:') & trailing '/'.
  def extracted_url(url)
    url.split('://', 2)[1].chomp('/')
  end

  # Return true iff the urls are "basically the same".
  # That is, they're the same ignoring the scheme
  # (this is true if the user switches between http and https)
  # and ignoring any trailing '/'.
  def basically_same(url1, url2)
    # Blank urls don't make any sense. Consider them not the same.
    return false if url1.blank?
    return false if url2.blank?

    extracted_url(url1) == extracted_url(url2)
  end

  # Number of days before a user may change repo_url. See below.
  # NOTE: If you change this value, you may also need to change
  # file config/locales/en.yml key repo_url_limits.
  REPO_URL_CHANGE_DELAY = 180

  # Return true iff the project can change its repo_url because the
  # REPO_URL_CHANGE_DELAY has expired
  def repo_url_delay_expired?
    repo_url_updated_at = @project.repo_url_updated_at
    return true if repo_url_updated_at.nil?

    repo_url_updated_at < REPO_URL_CHANGE_DELAY.days.ago
  end

  # Determine if there is a change in repo_url, and if there is,
  # if it's allowed.
  # We are trying to counter subtle attacks where
  # a project tries to claim the good reputation or effort of another project
  # by constantly switching its repo_url to other projects and/or nonsense.
  # The underlying problem is that names/identities are hard; the repo_url
  # (when present) is the closest to an "identity" that we have for a project.
  # We have to allow it to change sometimes (because it sometimes does), but
  # it should be a rare "sticky" event.
  # There are various special cases, e.g., you can always set the repo_url
  # if it's nil, the setter is an admin, or if only the scheme is changed.
  # But otherwise normal users can't change the repo_urls in less than
  # REPO_URL_CHANGE_DELAY days.  Allowing users to change repo_urls, but only
  # with large delays, reduces the administration effort required.
  def repo_url_change_allowed?
    return true unless @project.repo_url?
    return true if project_params[:repo_url].nil?
    return true if current_user.admin?

    return true if basically_same(project_params[:repo_url], @project.repo_url)

    repo_url_delay_expired?
  end

  def positive_integer?(value)
    !(value =~ /\A[1-9][0-9]{0,15}\z/).nil?
  end

  def integer_list?(value)
    !(value =~ /\A[1-9][0-9]{0,15}( *, *[1-9][0-9]{0,15}){0,20}\z/).nil?
  end

  # Purge data about this project from the CDN (if the CDN has any)
  def purge_cdn_project
    cdn_badge_key = @project.record_key
    FastlyRails.purge_by_key cdn_badge_key
  end

  # Maximum number of GitHub repos to retrieve when retrieving a list of
  # repos about a given user.  Limit this to prevent timeouts.
  # We have had past reports of problems when 80 repos are available, so
  # set this to a lower number.
  MAX_GITHUB_REPOS_FROM_USER = 50

  # Retrieve a set of (GitHub) repositories managed by the current user.
  # We intentionally retrieve a subset (to self-protect from overlong lists
  # that might lead to a timeout), so we prioritize recently pushed repos.
  # We omit repos that are already pursuing a badge.
  # rubocop:disable Style/MethodCalledOnDoEndBlock, Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def repo_data
    github = Octokit::Client.new access_token: session[:user_token]
    # Take extra steps to prevent a timeout when retrieving repo data.
    # If we enable auto_pagination we get a list of all the repos, but it
    # appears that GitHub sometimes hangs in those cases if the user has
    # a large number of repos.  David A. Wheeler suspects that problem is that
    # GitHub itself uses Rails and Rails doesn't stream JSON output by default;
    # that is fine for small datasets but can lead timeouts on larger datasets.
    # Thus, we no longer enable auto_paginate.
    # By default a call to github.repos will only return the first 30;
    # we pass a per_page value to control this.  For more information, see:
    # https://developer.github.com/v3/#pagination
    github.auto_paginate = false
    repos = github.repos(
      nil,
      sort: 'pushed', per_page: MAX_GITHUB_REPOS_FROM_USER
    )
    return if repos.blank?

    # Find & remove the repos already in our database.
    # We do this to make the user's job easier.
    repo_urls = repos.pluck(:html_url) # URLs of all of this user's repos
    already = Project.where(repo_url: repo_urls).pluck(:repo_url).to_set
    repos = repos.reject { |repo| already.member?(repo.html_url) }

    # Sort by name for user convenience:
    repos.sort_by! { |v| v['full_name'] }

    repos.map do |repo|
      [repo.full_name, repo.fork, repo.homepage, repo.html_url]
    end.compact
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Style/MethodCalledOnDoEndBlock, Metrics/MethodLength

  HTML_INDEX_FIELDS = 'projects.id, projects.name, description, ' \
                      'homepage_url, repo_url, license, projects.user_id, ' \
                      'achieved_passing_at, projects.updated_at, badge_percentage_0, ' \
                      'tiered_percentage'

  # Retrieve project data using the various query parameters.
  # The parameters determine what to select *and* fields to load
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def retrieve_projects
    @projects = Project.all
    # We had to keep this line the same to satisfy brakeman
    @projects = @projects.public_send params[:status] if
       %w[in_progress passing].include? params[:status]
    @projects = @projects.gteq(params[:gteq]) if params[:gteq].present?
    @projects = @projects.lteq(params[:lteq]) if params[:lteq].present?
    # "Prefix query" - query against *prefix* of a URL or name
    @projects = @projects.text_search(params[:pq]) if params[:pq].present?
    # "url query" - query for a URL match (home page or repo)
    @projects = @projects.url_search(params[:url]) if params[:url].present?
    # "Normal query" - text search against URL, name, and description
    # This will NOT match full URLs, but will match partial URLs.
    @projects = @projects.search_for(params[:q]) if params[:q].present?
    if params[:ids].present?
      @projects = @projects.where(id: params[:ids].split(',').map do |x|
                                        Integer(x)
                                      end)
    end
    @projects
  end

  # Subset to only the rows and fields we need
  def select_data_subset
    # If we're supplying html (common case), select only needed fields
    format = request&.format&.symbol
    if !format || format == :html
      @projects = @projects.select(HTML_INDEX_FIELDS)
    # JSON includes additional_rights; load them at one time to prevent
    # and N+1 query (do this for CSV also if we ever add that field to CSV)
    elsif format == :json
      @projects = @projects.includes(:additional_rights)
    end
    @pagy, @projects = pagy(@projects.includes(:user))
    # We want to know the *total* count, even if we're paging.
    # Pagy has to figure that out anyway, so instead of doing this:
    # # @count = @projects.count
    # we will extract it from pagy.
    @count = @pagy.count
    @pagy_locale = I18n.locale.to_s # Pagy requires a string version
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def set_homepage_url
    retrieved_repo_data = repo_data
    return if retrieved_repo_data.nil?

    # Assign to repo.homepage if it exists, and else repo_url
    repo = retrieved_repo_data.find { |r| @project.repo_url == r[3] }
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

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # TODO: Break this into smaller pieces
  def successful_update(format, old_badge_level, criteria_level)
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
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def url_anchor
    return '#' + params[:continue] unless params[:continue] == 'Save'

    ''
  end

  # Clean up url; returns nil if given nil.
  def clean_url(url)
    return url if url.nil?

    url.gsub(%r{\/+\z}, '')
  end
end
# rubocop:enable Metrics/ClassLength
