# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'addressable/uri'
require 'net/http'

# rubocop:disable Metrics/ClassLength
class ProjectsController < ApplicationController
  include ProjectsHelper

  # The 'badge', 'baseline_badge', and 'show_json' actions are special and
  # do NOT take a locale.
  skip_before_action :redir_missing_locale, only: %i[badge baseline_badge show_json]
  # The "project" table has many columns, and we often don't need them all.
  # So we'll take steps to only load a subset of the columns we need,
  # when we only need a subset. We need to load project data *before* using
  # that data (e.g., to check on who owns the project)
  # NOTE: Rails 8+ automatically raises ActiveModel::MissingAttributeError when
  # code tries to access attributes that weren't included in SELECT queries.
  before_action :set_project_all_values, only: %i[update show_json]
  before_action :set_criteria_level, only: %i[show edit update]
  before_action :set_project_for_section, only: %i[show edit]
  before_action :set_project_for_limited_fields, only: %i[delete_form destroy]
  before_action :require_logged_in, only: :create
  before_action :can_edit_else_redirect, only: %i[edit update]
  before_action :can_control_else_redirect, only: %i[destroy delete_form]
  before_action :require_adequate_deletion_rationale, only: :destroy
  before_action :cleanup_input_params, only: %i[create update]

  # Cache with CDN. We can only do this when we don't display the
  # header (which changes for logged-in users), use a flash, or
  # have a form to fill in (these use session values).
  # Note: 'show' is excluded because it displays user-specific content in HTML
  # and handles CDN caching itself for markdown format
  skip_before_action :set_default_cache_control,
                     only: %i[badge baseline_badge show_json]
  skip_before_action :setup_authentication_state,
                     only: %i[badge baseline_badge show_json]
  before_action :cache_on_cdn, only: %i[badge baseline_badge show_json]

  helper_method :repo_data

  # Cache control for show action - can be disabled via environment variable
  CACHE_SHOW_PROJECT = ENV['BADGEAPP_CACHE_SHOW_PROJECT'] != 'false'

  # These are the only allowed values for "sort" (if a value is provided)
  ALLOWED_SORT =
    %w[
      id name tiered_percentage
      achieved_passing_at achieved_silver_at achieved_gold_at
      homepage_url repo_url updated_at user_id created_at
    ].freeze

  ALLOWED_STATUS = %w[in_progress passing].freeze

  # Frozen constants for sort directions (memory optimization)
  ALLOWED_SORT_DIRECTIONS = %w[desc asc].freeze
  SORT_DIRECTION_ASC = ' asc'
  SORT_DIRECTION_DESC = ' desc'

  # Pre-computed sort strings to avoid string concatenation on every request
  # Maps: sort_field => { 'asc' => 'field asc', 'desc' => 'field desc' }
  # Disable cop for do...end with chained .freeze (required for frozen constant)
  # rubocop:disable Style/MethodCalledOnDoEndBlock
  SORT_STRINGS =
    ALLOWED_SORT.index_with do |field|
      {
        'asc' => "#{field} asc".freeze,
        'desc' => "#{field} desc".freeze
      }.freeze
    end.freeze
  # rubocop:enable Style/MethodCalledOnDoEndBlock

  # Pre-computed created_at sort strings for fallback ordering
  CREATED_AT_ASC = 'created_at asc'
  CREATED_AT_DESC = 'created_at desc'

  # Badge level ranks.
  # Higher rank = higher achievement. Used by badge_level_lost? to detect
  # when a project drops from a higher level to a lower one.
  # Metal and baseline are separate series; cross-series comparison returns
  # no loss (rank 0 for unknown levels).
  BADGE_LEVEL_RANK = {
    'in_progress' => 0,
    # Metal series
    'passing' => 1,
    'silver' => 2,
    'gold' => 3,
    # Baseline series
    'baseline-1' => 1,
    'baseline-2' => 2,
    'baseline-3' => 3
  }.freeze

  # Frozen regex for URL scheme extraction (memory optimization)
  URL_SCHEME_REGEX = %r{\A[^:]*://}

  # Frozen regexes for query parameter validation (memory optimization)
  # Used in positive_integer?() and integer_list?() methods
  POSITIVE_INTEGER_REGEX = /\A[1-9][0-9]{0,15}\z/
  INTEGER_LIST_REGEX = /\A[1-9][0-9]{0,15}( *, *[1-9][0-9]{0,15}){0,20}\z/

  INTEGER_QUERIES = %i[gteq lteq page].freeze

  TEXT_QUERIES = %i[pq q].freeze

  OTHER_QUERIES = %i[sort sort_direction status ids url].freeze

  ALLOWED_QUERY_PARAMS = (
    INTEGER_QUERIES + TEXT_QUERIES + OTHER_QUERIES
  ).freeze

  # Used to validate deletion rationale.
  AT_LEAST_15_NON_WHITESPACE = /\A\s*(\S\s*){15}.*/

  # Pattern matching SQL field characters requiring quoting (not a-z, 0-9, or _)
  NONTRIVIAL_SQL_FIELD_CHARACTER = /[^a-z0-9_]/

  # Given a SQL field name (as a string), return the fieldname
  # but quoted if necessary. This can only be called once there's a
  # Project.connection (quoting SQL fieldnames depends on the SQL engine)
  def self.quoted_sql_fieldname(f)
    if f.match?(NONTRIVIAL_SQL_FIELD_CHARACTER)
      Project.connection.quote_column_name(f)
    else
      f
    end
  end

  # Memory optimization: Pre-computed field lists when you only need
  # a limited number of fields. In many cases we don't even need them,
  # but a separate edit in (for example) the delete form might easily
  # add them, so let's avoid silent problems. Similarly, not having the
  # lock_version when you need it can be a big problem, so let's get it.
  # Include badge percentages for deletion email template.
  # Pre-computed as comma-separated SQL string to avoid array-to-string
  # conversion on every request (same optimization as PROJECT_FIELDS_FOR_SECTION).
  PROJECT_LIMITED_FIELDS = %i[
    id user_id name description homepage_url repo_url
    created_at updated_at lock_version
    tiered_percentage badge_percentage_0 badge_percentage_1 badge_percentage_2
  ].map { |f| quoted_sql_fieldname(f.to_s) }
                           .join(',').freeze

  # Memory optimization: Pre-computed field lists for selective Project loading
  # IMPORTANT: These lists control which fields are loaded from the database.
  # When adding new fields to Project model that are used in views, you MUST
  # add them to the appropriate list below or views will get nil values.
  #
  # Base fields always needed regardless of which section is being viewed
  # lock_version isn't needed for mere viewing, but it's a *big* problem
  # if we forget to include it where needed, so let's include it.
  # Base fields always needed for all project views/edits
  # Dynamically include saved flags for all levels
  PROJECT_BASE_FIELDS = (
    %i[
      id user_id name description homepage_url repo_url license entry_locale
      created_at updated_at tiered_percentage
      achieved_passing_at achieved_silver_at achieved_gold_at
      lost_passing_at lost_silver_at lost_gold_at
      lock_version disabled_reminders last_reminder_at
    ] + Sections::LEVEL_SAVED_FLAGS.values
  ).freeze

  # Levels that need project metadata fields (implementation_languages, etc.)
  LEVELS_WITH_METADATA = %w[0 baseline-1].freeze

  # Complete field lists for each section as SQL strings
  # Pre-computed as comma-separated strings to avoid runtime symbol-to-string
  # conversion and array splatting (saves ~130 objects per request)
  # Dynamically computed from Criteria data - updates automatically when criteria change
  # rubocop:disable Metrics/BlockLength
  PROJECT_FIELDS_FOR_SECTION =
    {}.tap do |hash|
      # Add fields for each criteria level section (passing, silver, gold, baseline-N)
      Project::LEVEL_IDS.each do |level_id|
        level_number = level_id
        level_name = Project::LEVEL_NUMBER_TO_NAME[level_number] || level_number

        fields = PROJECT_BASE_FIELDS.dup
        # Add badge percentage field for this criteria level
        fields << :"badge_percentage_#{level_number}"

        # Add project metadata fields (only used in level 0 / passing form)
        if LEVELS_WITH_METADATA.include?(level_number)
          fields << :implementation_languages << :general_comments << :cpe
        end

        # Add all criteria status and justification fields for this criteria level
        Criteria.active(level_number).each do |criterion|
          fields << :"#{criterion.name}_status"
          fields << :"#{criterion.name}_justification"
        end

        # The edit action checks notify_for_static_analysis?('0') for all levels,
        # so we need to ensure static_analysis fields (from passing level) are
        # loaded for silver and gold edit pages
        if level_number != '0' && level_number != 'baseline-1'
          fields << :static_analysis_status
          fields << :static_analysis_justification
        end

        # Convert to string, quoting only non-trivial column names
        quoted_fields =
          fields.map do |f|
            ProjectsController.quoted_sql_fieldname(f.to_s)
          end
        hash[level_name] = quoted_fields.join(',').freeze
      end

      # Add fields for permissions section (only uses base fields)
      quoted_base =
        PROJECT_BASE_FIELDS.map do |f|
          ProjectsController.quoted_sql_fieldname(f.to_s)
        end
      hash['permissions'] = quoted_base.join(',').freeze
    end.freeze # rubocop:disable Style/MethodCalledOnDoEndBlock
  # rubocop:enable Metrics/BlockLength

  # as= values, which redirect to alternative views
  ALLOWED_AS = %w[badge entry].freeze

  # Permitted criteria_level parameter (frozen array for memory optimization)
  CRITERIA_LEVEL_PERMITTED = [:criteria_level].freeze

  # "Normal case" index after projects are retrieved
  # @return [void]
  def show_normal_index
    select_data_subset
    sort_projects
    @projects
  end

  # Display projects index with filtering, sorting, and alternative view
  # redirects. Handles badge and entry view redirections.
  # Supports `GET /projects` and `GET /projects.json`.
  # @return [void]
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/BlockNesting
  def index
    validated_url = set_valid_query_url
    if validated_url == request.original_url
      retrieve_projects

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
          redirect_to "/#{locale}/projects/#{ids.first}#{suffix}",
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

  # Redirect to the single relevant badge entry, if there is one.
  # Handles cases where search results in 0, 1, or multiple matches.
  # @param id_list [Array<Integer>] List of project IDs from search
  # @return [void]
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
      redirect_to "/projects/#{id_list.first}/badge#{suffix}",
                  status: :moved_permanently
    end
  end
  # rubocop:disable Metrics/MethodLength

  # Display individual project details with criteria_level query fixes.
  # Redirects criteria_level queries (well-formed and malformed).
  # Note: Redirect for missing criteria_level is now handled in routes.rb
  # Display project section (passing, silver, gold, baseline-*, permissions).
  # Supports both HTML and Markdown formats.
  # Supports `GET /projects/:id/:section(.:format)`.
  # Note: Query parameter format (e.g., ?criteria_level=1) is handled by
  # redirect_to_default_section action before reaching this action.
  # @return [void]
  def show
    # Handle obsolete section names (e.g., "0" -> "passing", "bronze" -> "passing")
    redirect_obsolete_section_names

    # Use normalized section for rendering (set by before_action :set_criteria_level)
    @section = @criteria_level
    validate_section(@section)

    # Tell CDN the surrogate key so we can quickly erase cache later
    set_surrogate_key_header @project.record_key

    # Load section-specific data for rendering
    load_section_data_for_show(@section)

    # Enable CDN caching for markdown format (no user-specific content)
    cache_on_cdn if request.format.symbol == :md

    # Respond to different formats
    respond_to do |format|
      format.html # Renders projects/show.html.erb (single template for all sections)
      format.md { render_markdown_format }
    end
  end

  # Return project data in JSON format with CDN cache headers.
  # Supports `GET /projects/:id.json` (locale-independent).
  # Note: Locale-based JSON URLs are redirected by routes.rb before reaching this action.
  # @return [void]
  def show_json
    # Tell CDN the surrogate key so we can quickly erase it later
    set_surrogate_key_header @project.record_key
  end

  # Redirect bare project URL to default section.
  # Handles `GET (/:locale)/projects/:id(.:format)`.
  # Also handles legacy query parameter format: `GET /projects/:id?criteria_level=X`
  # Performance: Uses project ID directly without loading from database.
  # If project doesn't exist, the redirected URL will return 404.
  # @return [void]
  # rubocop:disable Metrics/AbcSize
  def redirect_to_default_section
    # Use project ID directly - no need to load project from database
    project_id = params[:id]

    # Preserve format if specified
    format_param = request.format.symbol == :html ? nil : request.format.symbol

    # Handle malformed query parameter format first
    if request.query_string.start_with?('criteria_level,')
      extracted_value = request.query_string.delete_prefix('criteria_level,')
      normalized = normalize_criteria_level(extracted_value)
      redirect_to project_section_path(project_id, normalized,
                                       locale: params[:locale],
                                       format: format_param),
                  status: :moved_permanently
      return
    end

    # Handle legacy query parameter format (redirect to path parameter)
    if request.query_parameters[:criteria_level].present?
      normalized = normalize_criteria_level(
        request.query_parameters[:criteria_level]
      )
      redirect_to project_section_path(project_id, normalized,
                                       locale: params[:locale],
                                       format: format_param),
                  status: :moved_permanently
      return
    end

    # Future: could read project.default_section from database
    default_section = Sections::DEFAULT_SECTION

    redirect_to project_section_path(project_id, default_section,
                                     locale: params[:locale],
                                     format: format_param),
                status: :found # 302 temporary (may become configurable)
  end
  # rubocop:enable Metrics/AbcSize

  # Display project deletion confirmation form.
  # Supports `GET /projects/:id/delete_form(.:format)`.
  # @return [void]
  def delete_form; end

  # Database fields needed for badge display (performance optimization)
  BADGE_PROJECT_FIELDS =
    'id, name, updated_at, tiered_percentage, ' \
    'badge_percentage_0, badge_percentage_1, badge_percentage_2'

  # Database fields needed for baseline badge display (performance optimization)
  BASELINE_BADGE_PROJECT_FIELDS =
    'id, name, updated_at, ' \
    'badge_percentage_baseline_1, badge_percentage_baseline_2, badge_percentage_baseline_3, ' \
    'achieved_baseline_1_at, achieved_baseline_2_at, achieved_baseline_3_at'

  # Generate and serve project badge in SVG or JSON format.
  # Optimized to select only necessary fields for performance.
  # @return [void]
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
    # We presume the CDN can associate multiple items with one key
    # (Fastly can), so that when we remove this key from the cache, all
    # related cache entries will be removed.
    set_surrogate_key_header @project.record_key

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

  # Generate and serve baseline badge in SVG or JSON format.
  # Optimized to select only necessary fields for performance.
  # @return [void]
  # rubocop:disable Metrics/MethodLength
  def baseline_badge
    # Select only the fields we need for performance
    @project = Project.select(BASELINE_BADGE_PROJECT_FIELDS).find(params[:id])

    # Tell CDN the surrogate key so we can quickly erase it later
    set_surrogate_key_header @project.record_key

    respond_to do |format|
      format.svg do
        send_data Badge[@project.baseline_badge_value],
                  type: 'image/svg+xml', disposition: 'inline'
      end
      format.json do
        render :baseline_badge, status: :ok, location: @project
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Display new project form with GitHub integration support.
  # Supports `GET /projects/new`.
  # @return [void]
  def new
    use_secure_headers_override(:allow_github_form_action)
    store_location_and_locale
    @project = Project.new
  end

  # Display project edit form.
  # Supports `GET /projects/:id/edit(.:format)`.
  # @return [void]
  def edit
    # Only check static analysis notification for criteria sections (not permissions)
    # Permissions section doesn't load criteria fields
    return if @criteria_level == 'permissions'

    # Run first-edit automation if this level hasn't been edited yet
    run_first_edit_automation_if_needed

    return unless @project.notify_for_static_analysis?('0')

    message = t('.static_analysis_updated_html')
    flash.now[:danger] = message
  end

  # Create a new project with automatic URL cleanup and duplicate detection.
  # Performs autofill and sends notification email on successful creation.
  # Supports `POST /projects` and `POST /projects.json`.
  # @return [void]
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
        existing_project = Project.select(:id).find_by(repo_url: project_repo_url)
        # Future: could read existing_project.default_section from database
        default_section = Sections::DEFAULT_SECTION
        return redirect_to project_section_path(existing_project, default_section)
      end
    end

    # Error out if homepage_url and repo_url are both empty... don't
    # do a save yet.

    @project.homepage_url ||= set_homepage_url
    # Clean up homepage URL
    if @project.homepage_url
      @project.homepage_url = clean_url(@project.homepage_url)
    end

    respond_to do |format|
      if @project.save
        @project.send_new_project_email
        # @project.purge_all
        flash[:success] = t('projects.new.thanks_adding')
        # Redirect to passing level edit form (explicit criteria_level required)
        format.html { redirect_to edit_project_section_path(@project, 'passing') }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json do
          render json: @project.errors, status: :unprocessable_content
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Update project with validation, autofill, and CDN cache management.
  # Handles ownership changes and repo URL restrictions.
  # Supports `PATCH/PUT /projects/1` and `PATCH/PUT /projects/1.json`.
  # @return [void]
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def update
    # Only accept updates if there's no repo_url change OR if change is ok
    if repo_url_unchanged_or_change_allowed?
      # Send CDN purge early, to give it time to distribute purge request
      @project.purge_cdn_project
      # Capture the level being worked on (baseline or traditional badge)
      old_badge_level = current_working_level(@criteria_level, @project)
      final_project_params = project_params
      # Determine if we're trying to change ownership.
      # Only admins and owner (can_control?) can change ownership
      new_owner = final_project_params[:user_id]
      owner_change = new_owner.present? &&
                     (new_owner == final_project_params[:user_id_repeat]) &&
                     User.exists?(id: new_owner)
      if !can_control? || !owner_change
        final_project_params = final_project_params.except('user_id')
      end
      final_project_params = final_project_params.except('user_id_repeat')

      # Track which fields user is trying to change
      changed_fields = final_project_params.keys.map(&:to_sym)

      # Apply user's changes first
      final_project_params.each do |key, user_value| # mass assign
        @project[key] = user_value
      end

      # Capture what the user just set (BEFORE Chief runs)
      user_set_values = {}
      changed_fields.each do |field|
        user_set_values[field] = @project[field]
      end

      # Run Chief analysis with level and changed_fields for targeted validation
      # Pass user_set_values so we can detect overrides
      run_save_automation(changed_fields, user_set_values)

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
          # We must send a purge later, not just now, due to a subtle race
          # condition. Here's what is going on.
          # The server and the CDN communicate over TCP/IP. This *server*
          # will always produce the newest information once it's committed.
          # However, TCP/IP does *NOT* guarantee that different replies
          # from a server will be received (by the CDN) in the same order that
          # they were sent. This means that the CDN can receive *old* data
          # after # receiving a purge request and newer data, resulting in
          # a CDN caches with obsolete data that will be held for a long time.
          # A solution: Wait a short time, then send *another* purge. That way
          # even if the CDN receives updates out-of-order, that old data will
          # be purged. The next request following this additional purge will
          # receive the updated data, and then the CDN will have correct data.
          #
          # Note: ActiveJob by default stores jobs in RAM. If the system is
          # restarted while a job is active, and jobs are stored in RAM, the
          # job will be lost and not executed. The long-term solution is to put
          # jobs in the database.
          PurgeCdnProjectJob.set(
            wait: BADGE_PURGE_DELAY.seconds
          ).perform_later(@project.record_key)
          # Also send CDN purge last, to increase likelihood of being purged
          # and replaced with correct data even before the delayed purpose.
          @project.purge_cdn_project
        else
          format.html { render :edit, criteria_level: @criteria_level }
          format.json do
            render json: @project.errors, status: :unprocessable_content
          end
        end
      end
    else
      flash.now[:danger] = t('projects.edit.repo_url_limits')
      render :edit
    end
  rescue ActiveRecord::StaleObjectError
    message = t('projects.edit.changed_since_html',
                edit_url: edit_project_section_url(@project, @criteria_level))
    flash.now[:danger] = message
    render :edit, status: :conflict
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  # Delete project and send notification email with rationale.
  # Purges CDN cache and redirects to project list.
  # Supports `DELETE /projects/1` and `DELETE /projects/1.json`.
  # Form parameter **deletion_rationale** has the user-provided rationale.
  # @return [void]
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
    @project.purge_cdn_project
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Database fields for feed display (performance optimization).
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
                        'homepage_url, repo_url, description, entry_locale, user_id'

  # Generate Atom feed of recently updated projects.
  # @return [void]
  def feed
    # @projects = Project.select(FEED_DISPLAY_FIELDS).
    #  limit(50).reorder(updated_at: :desc, id: :asc).includes(:user)
    @projects = Project.select(FEED_DISPLAY_FIELDS).recently_updated
    respond_to { |format| format.atom }
  end

  # Display reminders summary for admin users only.
  # @return [void]
  def reminders_summary
    if current_user_is_admin?
      respond_to { |format| format.html }
    else
      flash[:danger] = t('admin_only')
      redirect_to root_path
    end
  end

  # Regex pattern for validating repository rights changes.
  # Rights changes, if provided, must match this pattern.
  VALID_ADD_RIGHTS_CHANGES = /\A *[+-] *\d+ *(, *\d+)*\z/

  # Number of days before a user may change repo_url.
  # NOTE: If you change this value, you may also need to change
  # file `config/locales/en.yml` key `repo_url_limits`.
  REPO_URL_CHANGE_DELAY = 180

  # Maximum number of GitHub repositories to fetch from a user.
  # We have had past reports of problems when 80 repos are available, so
  # set this to a lower number.
  MAX_GITHUB_REPOS_FROM_USER = 50

  # Database fields for HTML index display (performance optimization)
  HTML_INDEX_FIELDS = 'projects.id, projects.name, description, entry_locale, ' \
                      'homepage_url, repo_url, license, projects.user_id, ' \
                      'achieved_passing_at, projects.updated_at, ' \
                      'badge_percentage_0, tiered_percentage'

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
  # Sends monthly announcement emails for projects that achieved badges.
  # Generates and delivers a report email with statistics comparing the
  # previous month to the month before that, highlighting new badge recipients.
  # @return [Array<Integer>] Array of project IDs that newly achieved passing
  #   badge status in the previous month
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
    projects.first.ids
  end
  # rubocop:enable Metrics/MethodLength
  private_class_method :send_monthly_announcement

  # Validates if a query parameter key-value pair is allowed.
  # Performs validation based on parameter type (integer, text, or other).
  # @param key [String] The query parameter key to validate
  # @param value [String] The query parameter value to validate
  # @return [Boolean] True if the query parameter is allowed, false otherwise
  def allowed_query?(key, value)
    return false if value.blank?
    return positive_integer?(value) if INTEGER_QUERIES.include?(key.to_sym)
    return TextValidator.new(attributes: %i[query]).text_acceptable?(value) if
      TEXT_QUERIES.include?(key.to_sym)

    allowed_other_query?(key, value)
  end

  # Validates specific query parameter types not covered by general validation.
  # Handles special parameter types like sort, sort_direction, status, etc.
  # @param key [String] The query parameter key to validate
  # @param value [String] The query parameter value to validate
  # @return [Boolean] True if the query parameter is allowed, false otherwise
  # rubocop:disable Metrics/CyclomaticComplexity
  def allowed_other_query?(key, value)
    return ALLOWED_SORT.include?(value) if key == 'sort'
    return ALLOWED_SORT_DIRECTIONS.include?(value) if key == 'sort_direction'
    return ALLOWED_STATUS.include?(value) if key == 'status'
    return integer_list?(value) if key == 'ids'
    return ALLOWED_AS.include?(value) if key == 'as'
    return true if key == 'url'

    false
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # Convert all status fields from strings to integers in hash h.
  # This modifies the hash IN PLACE.
  # Invalid values are left as-is and will be caught by model validations,
  # which provide proper error messages to users.
  # @param h [Hash] The hash to modify (typically params[:project])
  # @return [void]
  def convert_status_params_of_hash!(h)
    Project::ALL_CRITERIA_STATUS.each do |status_field|
      string_value = h[status_field]
      # NOTE: In Ruby, empty string is truthy (not falsy)
      next unless string_value # Skip if nil, false, or key doesn't exist

      # Skip if already an integer (shouldn't happen, but be safe)
      next if string_value.is_a?(Integer)

      integer_value = CriterionStatus::STATUS_BY_NAME[string_value]

      if integer_value
        # Valid value - convert to integer
        h[status_field] = integer_value
      else
        # Invalid value - leave as-is (don't convert)
        # Model validations will catch it and provide error message
        # Log for security monitoring
        Rails.logger.warn "Invalid status value for #{status_field}: #{string_value.inspect}"
      end
    end
  end

  # Convert all empty justification strings to nil in hash h.
  # This modifies the hash IN PLACE.
  # @param h [Hash] The hash to modify (typically params[:project])
  # @return [void]
  def convert_justification_params_of_hash!(h)
    Project::ALL_CRITERIA_JUSTIFICATION.each do |justification_field|
      value = h[justification_field]

      # NOTE: In Ruby, empty string is truthy (not falsy)
      next unless value # Skip if nil, false, or key doesn't exist

      # Only process if it's a String (skip if already nil or other type)
      next unless value.is_a?(String)

      # Convert empty strings to nil
      # Leave non-empty strings as-is
      h[justification_field] = nil if value == ''
    end
  end

  # Clean up input project data.
  # Turn status values into integers, and convert
  # empty justification values into nil.
  # @return [void]
  def cleanup_input_params
    p = params[:project]
    return unless p

    # We have project parameters. Clean them up. This way, external
    # systems can use string status (e.g., 'Met') and empty strings,
    # but internally we use integer and nil for efficiency.
    convert_status_params_of_hash!(p)
    convert_justification_params_of_hash!(p)
  end

  # Verifies that the current user can edit the project, or redirects to root.
  # Used as a before_action filter to enforce edit permissions.
  # @return [Boolean] True if user can edit, otherwise redirects to root path
  def can_edit_else_redirect
    return true if can_edit?

    redirect_to root_path
  end

  # Verifies that the current user can control the project or redirects to root.
  # Used as a before_action filter to enforce control permissions.
  # @return [Boolean] True if user can control, otherwise redirects to root
  def can_control_else_redirect
    return true if can_control?

    redirect_to root_path
  end

  # Validates that deletion rationale meets minimum requirements.
  # Ensures non-admin users provide adequate justification (20+ chars with
  # 15+ non-whitespace) for project deletion to prevent abuse.
  # @return [Boolean] True if rationale is adequate, otherwise redirects
  #   to deletion form with error message
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

  # Forcibly updates additional rights for a project with validated input.
  # Adds or removes user edit permissions based on command prefix.
  # Assumes permissions are validated and syntax is correct.
  # @param id [Integer] The project ID to update
  # @param new_additional_rights [String] Command string with format
  #   "+user1,user2" (add) or "-user1,user2" (remove)
  # @return [void]
  # rubocop:disable Metrics/MethodLength
  def update_additional_rights_forced(id, new_additional_rights)
    command = new_additional_rights[0] # rubocop:disable Style/ArrayFirstLast
    new_list = new_additional_rights[1..].split(',').map(&:to_i).sort.uniq
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

  # Validates and processes additional rights changes from request parameters.
  # Performs input validation and permission checks before delegating to
  # update_additional_rights_forced. Only users with control permissions
  # can remove additional editors.
  # @return [void] Silently returns if validation fails or no changes requested
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
    return if additional_rights_changes.first == '-' && !can_control?

    update_additional_rights_forced(@project.id, additional_rights_changes)
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # Creates a GitHub client factory based on current user authentication.
  # Returns authenticated client if user is logged in via GitHub, otherwise
  # returns unauthenticated client.
  # @return [Proc] A procedure that returns an Octokit::Client instance
  def client_factory
    proc do
      if current_user.nil? || current_user.provider != 'github'
        Octokit::Client.new
      else
        Octokit::Client.new access_token: session[:user_token]
      end
    end
  end

  # Filters request parameters to only allow whitelisted project fields.
  # Security measure to prevent mass assignment vulnerabilities.
  # @return [ActionController::Parameters] Permitted parameters for project
  def project_params
    params.expect(project: Project::PROJECT_PERMITTED_FIELDS)
  end

  # Permits and extracts criteria_level parameter from request.
  # Used for filtering projects by criteria level.
  # @return [ActionController::Parameters] Permitted criteria_level parameter
  def criteria_level_params
    params.permit(CRITERIA_LEVEL_PERMITTED)
  end

  # Extracts URL without scheme and trailing slash for comparison.
  # Used for URL normalization when checking if URLs are essentially the same.
  # @param url [String] The URL to extract and normalize
  # @return [String] Normalized URL without scheme and trailing slash
  def extracted_url(url)
    # Extract everything after scheme (http:// or https://) without array allocation
    # Use frozen regex constant to avoid regex recompilation
    url.sub(URL_SCHEME_REGEX, '').chomp('/')
  end

  # Compares two URLs to determine if they are essentially the same.
  # Ignores differences in scheme (http vs https) and trailing slashes.
  # Used for validating repo URL changes.
  # @param url1 [String] First URL to compare
  # @param url2 [String] Second URL to compare
  # @return [Boolean] True if URLs are basically the same, false otherwise
  def basically_same?(url1, url2)
    # Blank urls don't make any sense. Consider them not the same.
    return false if url1.blank?
    return false if url2.blank?

    extracted_url(url1) == extracted_url(url2)
  end

  # Checks if the repository URL change delay period has expired.
  # Projects can only change repo URLs after a delay to prevent abuse.
  # @return [Boolean] True if delay has expired or no previous update recorded
  def repo_url_delay_expired?
    repo_url_updated_at = @project.repo_url_updated_at
    return true if repo_url_updated_at.nil?

    repo_url_updated_at < REPO_URL_CHANGE_DELAY.days.ago
  end

  # Validates if a change is allowed w.r.t. repository URL changes (if any).
  # If the URL isn't being changed, returns true.
  # Otherwise, whether or not it's allowed depends on various factors.
  # Prevents subtle attacks where projects switch URLs to claim reputation
  # of other projects. Allows changes in special cases (admin users, scheme
  # changes only, or after delay period).
  # @return [Boolean] True if repo URL change is allowed, false otherwise
  def repo_url_unchanged_or_change_allowed?
    return true unless @project.repo_url?
    return true if project_params[:repo_url].nil?
    return true if current_user.admin?

    return true if basically_same?(project_params[:repo_url], @project.repo_url)

    repo_url_delay_expired?
  end

  # Validates if a string represents a positive integer.
  # Accepts 1-16 digit positive integers (no leading zeros except for "0").
  # @param value [String] The string value to validate
  # @return [Boolean] True if string is a valid positive integer
  def positive_integer?(value)
    # Use frozen regex constant to avoid regex recompilation
    value.match?(POSITIVE_INTEGER_REGEX)
  end

  # Validates if a string represents a comma-separated list of integers.
  # Accepts up to 21 positive integers separated by commas with optional spaces.
  # @param value [String] The string value to validate as integer list
  # @return [Boolean] True if string is a valid integer list
  def integer_list?(value)
    # Use frozen regex constant to avoid regex recompilation
    value.match?(INTEGER_LIST_REGEX)
  end

  # Maximum number of GitHub repos to retrieve when retrieving a list of
  # repos about a given user.  Limit this to prevent timeouts.
  # We have had past reports of problems when 80 repos are available, so
  # set this to a lower number.

  # Retrieves GitHub repositories managed by the current user.
  # Returns prioritized recently-pushed repos, excluding those already
  # pursuing badges. Limits results to prevent timeouts.
  # @param github [Octokit::Client, nil] Optional GitHub client instance
  # @return [Array<Array>, nil] Array of repo data arrays [name, fork,
  #   homepage, html_url] or nil if unauthorized/no repos
  # rubocop:disable Style/MethodCalledOnDoEndBlock, Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def repo_data(github = nil)
    github ||= Octokit::Client.new access_token: session[:user_token]
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
    # We only fetch public repos since badges are only for public projects.
    github.auto_paginate = false
    begin
      repos = github.repos(
        nil,
        type: 'public', sort: 'pushed', per_page: MAX_GITHUB_REPOS_FROM_USER
      )
    rescue Octokit::Unauthorized
      return
    end
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
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Style/MethodCalledOnDoEndBlock, Metrics/MethodLength

  # Retrieves and filters project data based on query parameters.
  # Applies various filters including status, comparison operators, text
  # search, URL search, and ID lists to build the projects query.
  # @return [ActiveRecord::Relation] Filtered projects relation
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

  # Optimizes data selection and implements pagination.
  # Selects minimal fields for HTML requests, includes associations for JSON
  # to prevent N+1 queries, and sets up pagination with count tracking.
  # @return [void] Modifies @projects, @pagy, @count, and @pagy_locale instance
  #   variables
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

  # Sets the homepage URL for a project based on GitHub repository data.
  # Prefers the repository's homepage field if available, otherwise uses
  # the repository URL itself.
  # @return [String, nil] The determined homepage URL or nil if no repo data
  def set_homepage_url
    retrieved_repo_data = repo_data
    return if retrieved_repo_data.nil?

    # Assign to repo.homepage if it exists, and else repo_url
    repo = retrieved_repo_data.find { |r| @project.repo_url == r[3] }
    return if repo.nil?

    repo[2].present? ? repo[2] : @project.repo_url
  end

  # Callback to load project instance from params[:id].
  # This loads *ALL* values of a project (we don't use select first).
  # Used as before_action to set @project for actions that need it.
  # @return [void] Sets @project instance variable
  def set_project_all_values
    @project = Project.find(params[:id])
  end

  # Load project data for limited fields.
  def set_project_for_limited_fields
    @project = Project.select(PROJECT_LIMITED_FIELDS).find(params[:id])
  end

  # Optimized project loading for section-based actions - loads only needed fields.
  # Used by show and edit actions which are section-specific.
  # Memory optimization: Loads only base fields + fields of the current section
  # Saves ~438 objects (34.5%) per request when displaying a specific section,
  # when we only had passing/silver/gold/baseline-1, and that savings is
  # expected to increase over time.
  # We receive a brutally large number of "show" and "edit" requests, so
  # optimizing these (e.g., reducing objects created each time) is worth doing.
  # Falls back to loading all fields if section is unknown.
  # @return [void] Sets @project instance variable
  def set_project_for_section
    # Look up pre-calculated SQL field list for this section
    section = @criteria_level # NOTE: @criteria_level actually contains the section name
    fields_to_load = PROJECT_FIELDS_FOR_SECTION[section]

    # Load project with selected fields, or all fields if section unknown
    @project =
      if fields_to_load
        Project.select(fields_to_load).find(params[:id])
      else
        # Unknown section - load all fields as fallback
        Project.find(params[:id])
      end
  end

  # Load section-specific data for show action
  # Only loads data needed for the requested section (performance optimization)
  # @param section [String] section name (e.g., 'passing', 'permissions')
  # @return [void] Sets instance variables for view rendering
  def load_section_data_for_show(section)
    # Different sections need different data
    # For now, all data loading is handled by set_project_for_section
    # which optimizes field selection based on section
    # Permissions section: no criteria needed, just render the view
    # Criteria sections: @project already loaded with optimized fields
    # This method is a placeholder for future section-specific loading
  end

  # Sets and validates criteria level/section from parameters.
  # Checks for :section path parameter first (new routing),
  # then falls back to criteria_level query parameter (legacy URLs).
  # Ensures criteria_level is a valid level, defaulting to 'passing'.
  # Normalizes numeric forms (0,1,2) and deprecated names to canonical text forms.
  # @return [void] Sets @criteria_level instance variable
  def set_criteria_level
    # Prefer :section path parameter (new routing), fall back to query parameter (legacy)
    level_param = params[:section] ||
                  criteria_level_params[:criteria_level] ||
                  Sections::DEFAULT_SECTION
    @criteria_level = normalize_criteria_level(level_param)
  end

  # Redirects obsolete section names to their canonical equivalents.
  # Handles deprecated section names with permanent redirect (301).
  # @return [void] Performs redirect if obsolete section name found
  def redirect_obsolete_section_names
    raw_section = params[:section]
    return unless raw_section && Sections::REDIRECTS.key?(raw_section)

    canonical = Sections::REDIRECTS[raw_section]
    redirect_to project_section_path(@project, canonical, locale: params[:locale]),
                status: :moved_permanently
  end

  # Validates that the section name is canonical (not obsolete).
  # Note: This validation is primarily defensive - in practice:
  # 1. Routes only allow sections matching VALID_SECTION_REGEX
  # 2. redirect_obsolete_section_names redirects all obsolete sections
  # 3. Therefore only canonical sections reach this point
  # @param section [String] The section name to validate
  # @return [void] Returns if section is canonical
  def validate_section(section)
    # All sections should be canonical by this point due to route constraints
    # and redirect_obsolete_section_names handling obsolete names
    return if Sections::ALL_CANONICAL_NAMES.include?(section)

    # This should never be reached in normal operation - defensive only
    # If reached, indicates a bug in section validation or redirect logic
    raise ActionController::RoutingError, "Invalid section: #{section}"
  end

  # Renders the markdown format for project show.
  # Only criteria sections support markdown (not permissions).
  # @raise [ActionController::RoutingError] If permissions section requests markdown
  # @return [void]
  def render_markdown_format
    if @section == 'permissions'
      raise ActionController::RoutingError,
            'Markdown format not supported for permissions section'
    end
    render 'projects/show_markdown', layout: false,
           content_type: 'text/markdown'
  end

  # Generates a clean URL by removing invalid query parameters.
  # Validates query parameters and rebuilds URL with only allowed ones,
  # removing empty query strings entirely.
  # @return [String] Cleaned URL with valid query parameters only
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

  # Applies sorting to the projects collection based on URL parameters.
  # Validates sort parameter against allowed values and applies direction
  # (asc/desc) with fallback ordering by created_at.
  # @return [void] Modifies @projects instance variable with new ordering
  # rubocop:disable Metrics/AbcSize
  def sort_projects
    # Sort, if there is a requested order (otherwise use default created_at)
    return if params[:sort].blank? || ALLOWED_SORT.exclude?(params[:sort])

    # Use pre-computed frozen strings to avoid allocations
    direction = params[:sort_direction] == 'desc' ? 'desc' : 'asc'
    @projects = @projects
                .reorder(SORT_STRINGS[params[:sort]][direction])
                .order(direction == 'desc' ? CREATED_AT_DESC : CREATED_AT_ASC)
  end
  # rubocop:enable Metrics/AbcSize

  # Handles successful project update responses and badge level changes.
  # Generates appropriate redirects, sends status change emails, and displays
  # congratulations or warning messages based on badge level changes.
  # @param format [ActionController::MimeResponds::Collector] Response format
  # @param old_badge_level [String] Previous badge level before update
  # @param criteria_level [String] Current criteria level for navigation
  # @return [void] Renders response and sends emails as needed
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  # TODO: Break this into smaller pieces
  def successful_update(format, old_badge_level, criteria_level)
    # Use Sections::DEFAULT_SECTION instead of hardcoded 'passing'
    section = criteria_level || Sections::DEFAULT_SECTION
    # @project.purge
    format.html do
      # Check if Chief failed during save
      if @chief_failed
        flash[:warning] = t('projects.edit.automation.analysis_failed',
                            count: @chief_failed_fields&.size || 0,
                            fields: @chief_failed_fields&.join(', ') || '')
        redirect_to edit_project_section_path(@project, section,
                                              locale: params[:locale])
      # "Save and Continue" - always go back to edit
      elsif params[:continue]
        if @overridden_fields&.any?
          handle_overridden_fields_redirect(section)
        else
          flash[:info] = t('projects.edit.successfully_updated')
          redirect_to edit_project_section_path(@project, section,
                                                locale: params[:locale]) + url_anchor
        end
      # "Save and Exit" - check for forced overrides
      elsif @overridden_fields&.any?
        # Forced overrides - redirect to edit with warning (not show page)
        handle_overridden_fields_redirect(section)
      else
        # Normal save - exit to show page
        redirect_to project_section_path(@project, section,
                                         locale: params[:locale]),
                    success: t('projects.edit.successfully_updated')
      end
    end
    format.json do
      handle_json_response_with_automation
    end
    # Check if the level being worked on has changed
    new_badge_level = current_working_level(criteria_level, @project)
    return if new_badge_level == old_badge_level

    # TODO: Eventually deliver_later
    ReportMailer.project_status_change(
      @project, old_badge_level, new_badge_level
    ).deliver_now
    # Determine if this represents a gain or loss of badge status
    lost_level = badge_level_lost?(old_badge_level, new_badge_level)
    if lost_level
      flash[:danger] = t('projects.edit.lost_badge')
    else
      flash[:success] = t(
        'projects.edit.congrats_new',
        new_badge_level: new_badge_level
      )
    end
    ReportMailer.email_owner(
      @project, old_badge_level, new_badge_level, lost_level
    ).deliver_now
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # Generates URL anchor fragment for form navigation.
  # Creates anchor tag for specific form sections, excluding the generic "Save".
  # @return [String] URL anchor fragment (e.g., "#section_name") or empty string
  def url_anchor
    return '#' + params[:continue] unless params[:continue] == 'Save'

    ''
  end

  # Determines the current working level based on criteria level or badge level.
  # For baseline levels, returns the criteria level being edited.
  # For traditional badge levels, returns the project's actual badge level.
  # @param criteria_level [String, nil] The criteria level being edited
  # @param project [Project] The project whose badge level to check
  # @return [String] The current working level
  def current_working_level(criteria_level, project)
    if Project::CRITERIA_SERIES[:baseline].include?(criteria_level)
      criteria_level
    else
      project.badge_level
    end
  end

  # Determines if a badge level change represents a loss of status.
  # Compares ranks within BADGE_LEVEL_RANK; unknown levels default to 0.
  # Cross-series comparisons (e.g., metal to baseline) return false since
  # they represent different badge types, not a downgrade.
  # @param old_level [String] Previous badge level
  # @param new_level [String] New badge level
  # @return [Boolean] True if the change represents a loss of badge status
  def badge_level_lost?(old_level, new_level)
    (BADGE_LEVEL_RANK[new_level] || 0) < (BADGE_LEVEL_RANK[old_level] || 0)
  end

  # Normalizes URLs by removing trailing slashes.
  # Ensures consistent URL format for comparison and storage.
  # @param url [String, nil] The URL to clean
  # @return [String, nil] Cleaned URL without trailing slashes, or nil if
  #   input was nil
  def clean_url(url)
    return url if url.nil?

    # Remove all trailing slashes. Even "/" becomes the empty string
    url = url.chop while url.end_with?('/')
    url
  end

  # Run first-edit automation if this badge level hasn't been saved yet.
  # Tracks which fields were filled (for highlighting in view).
  def run_first_edit_automation_if_needed
    return if level_already_saved?

    # Capture original values before automation
    original_values = capture_original_values

    # Run Chief analysis for this specific level
    chief = Chief.new(@project, client_factory, entry_locale: @project.entry_locale)
    chief.autofill(level: @criteria_level)

    # Track which fields were changed (for highlighting)
    @automated_fields = find_automated_fields(original_values)
    @overridden_fields = [] # No overrides on first edit (all were '?')

    # Mark this level as saved so we don't re-run automation
    set_level_saved_flag(true)
  end

  # Check if current badge level has already been saved/edited
  # @return [Boolean]
  def level_already_saved?
    flag_name = level_saved_flag_name
    return false unless flag_name

    @project.public_send(flag_name)
  end

  # Get the flag name for the current badge level
  # @return [Symbol, nil]
  def level_saved_flag_name
    Sections::LEVEL_SAVED_FLAGS[@criteria_level]
  end

  # Mark the saved flag for the current badge level
  # @param value [Boolean]
  # rubocop:disable Naming/AccessorMethodName, Rails/SkipsModelValidations
  def set_level_saved_flag(value)
    flag_name = level_saved_flag_name
    # Use update_column to avoid triggering callbacks during automation
    @project.update_column(flag_name, value) if flag_name
  end
  # rubocop:enable Naming/AccessorMethodName, Rails/SkipsModelValidations

  # Capture original field values for this level before automation
  # @return [Hash] Field name => current value
  def capture_original_values
    original = {}
    # Convert level to internal format for Criteria.active
    internal_level = criteria_level_to_internal(@criteria_level)
    Criteria.active(internal_level).each do |criterion|
      field_name = :"#{criterion.name}_status"
      original[field_name] = @project.public_send(field_name)
    end
    original
  end

  # Find which fields were automatically filled (changed from '?' or nil)
  # @param original_values [Hash] Original field values
  # @return [Array<Symbol>] List of field names that were filled
  def find_automated_fields(original_values)
    automated = []
    original_values.each do |field_name, old_value|
      new_value = @project.public_send(field_name)
      # Field was automated if it was '?' or blank and now has a value
      if (old_value.blank? || old_value == '?') && new_value.present? && new_value != '?'
        automated << field_name
      end
    end
    automated
  end

  # Categorize a single Chief proposal (override vs automated)
  # @param field [Symbol] Field name
  # @param data [Hash] Chief proposal with :value, :explanation, :forced
  # @param user_value [Object] Value user set
  # rubocop:disable Metrics/MethodLength
  def categorize_chief_proposal(field, data, user_value)
    chief_value = data[:value]

    # Only track if Chief is changing what the user set
    return if user_value == chief_value

    if user_value.present? && user_value != '?'
      # Chief is overriding a real value user set - ORANGE
      @overridden_fields << {
        field: field,
        old_value: user_value,
        new_value: chief_value,
        explanation: data[:explanation]
      }
    elsif user_value == '?' || user_value.blank?
      # Chief is filling in an unknown - YELLOW
      @automated_fields << {
        field: field,
        new_value: chief_value,
        explanation: data[:explanation]
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Run Chief automation during save with override detection
  # @param changed_fields [Array<Symbol>] Fields that user modified
  # @param user_set_values [Hash] Values that user just set (before Chief)
  # rubocop:disable Metrics/MethodLength
  def run_save_automation(changed_fields, user_set_values)
    chief = Chief.new(@project, client_factory, entry_locale: @project.entry_locale)
    proposed_changes = chief.propose_changes(
      level: @criteria_level,
      changed_fields: changed_fields
    )

    # Track which fields will be overridden BEFORE applying changes
    @overridden_fields = []
    @automated_fields = []

    proposed_changes.each do |field, data|
      # Skip non-forced suggestions
      next unless data[:forced]

      categorize_chief_proposal(field, data, user_set_values[field])
    end

    # Now apply Chief's changes
    chief.apply_changes(@project, proposed_changes)

    # Mark level as saved (automation ran)
    set_level_saved_flag(true)
  rescue StandardError => e
    handle_chief_save_failure(e, changed_fields, user_set_values)
  end
  # rubocop:enable Metrics/MethodLength

  # Handle Chief failures during save
  # @param error [StandardError] The exception that occurred
  # @param changed_fields [Array<Symbol>] Fields user tried to change
  # @param user_set_values [Hash] Values user set before Chief ran
  def handle_chief_save_failure(error, changed_fields, user_set_values)
    Rails.logger.error("Chief analysis failed during save: #{error.class} #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))

    # Find which fields might have been affected by Chief
    potentially_overridable = find_overridable_fields_for_level(changed_fields)

    # Restore user's input for overridable fields
    potentially_overridable.each do |field|
      if user_set_values.key?(field)
        @project[field] = user_set_values[field]
      end
    end

    # Set error info for flash message
    @chief_failed = true
    @chief_failed_fields = potentially_overridable
  end

  # Find which changed fields are potentially overridable by Chief
  # @param changed_fields [Array<Symbol>] Fields that were changed
  # @return [Array<Symbol>] Fields that are overridable
  def find_overridable_fields_for_level(changed_fields)
    # Get all overridable fields from all detectives
    all_overridable = Set.new
    Chief::ALL_DETECTIVES.each do |detective_class|
      all_overridable.merge(detective_class::OVERRIDABLE_OUTPUTS)
    end

    # Return intersection
    changed_fields.select { |f| all_overridable.include?(f) }
  end

  # Format override details for flash message
  # @return [String] Formatted override details
  def format_override_details
    details =
      @overridden_fields.map do |r|
        criterion = Criteria[criteria_level_to_internal(@criteria_level)][r[:field]]
        criterion_name = criterion&.title || r[:field].to_s.humanize
        t('projects.edit.automation.override_detail',
          criterion: criterion_name,
          old: r[:old_value],
          new: r[:new_value],
          explanation: r[:explanation])
      end
    details.join("\n")
  end

  # Handle redirect to edit form with overridden fields highlighted
  # @param section [String] The section/level being edited
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def handle_overridden_fields_redirect(section)
    # Build detailed flash message
    override_details = format_override_details

    flash[:warning] = t('projects.edit.automation.chief_overrode',
                        count: @overridden_fields.size) + "\n" + override_details

    # Log overrides for monitoring
    Rails.logger.info(
      "Chief override: project=#{@project.id} user=#{current_user&.id} " \
      "fields=#{@overridden_fields.pluck(:field).join(',')}"
    )

    # Redirect with highlight parameters
    overridden_field_names = @overridden_fields.map { |r| r[:field].to_s }
    automated_field_names = @automated_fields.map { |r| r[:field].to_s }
    first_overridden = overridden_field_names.first

    redirect_to edit_project_section_path(
      @project,
      section,
      locale: params[:locale],
      anchor: first_overridden,
      overridden: overridden_field_names.join(','),
      automated: automated_field_names.join(',')
    )
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Build automation metadata for JSON response
  # @return [Hash] Automation details (overridden and automated fields)
  # rubocop:disable Metrics/MethodLength
  def build_automation_metadata
    {
      overridden: @overridden_fields&.map do |r|
        {
          field: r[:field],
          old_value: r[:old_value],
          new_value: r[:new_value],
          explanation: r[:explanation]
        }
      end || [],
      automated: @automated_fields&.map do |r|
        {
          field: r[:field],
          value: r[:new_value],
          explanation: r[:explanation]
        }
      end || []
    }
  end
  # rubocop:enable Metrics/MethodLength

  # Handle JSON response with automation details
  def handle_json_response_with_automation
    response_data = {
      id: @project.id,
      status: 'updated',
      message: 'Project updated successfully'
    }

    if @overridden_fields&.any? || @automated_fields&.any?
      response_data[:automation] = build_automation_metadata
    end

    render json: response_data, status: :ok
  end
end
# rubocop:enable Metrics/ClassLength
