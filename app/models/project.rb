# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/ClassLength
class Project < ApplicationRecord
  has_many :additional_rights, dependent: :destroy
  cattr_accessor :skip_callbacks
  # We could add something like this:
  # + has_many :users, through: :additional_rights
  # but we don't, because we don't use the other information about those users.
  # We only need the user_ids and the additional_rights table has that.

  using StringRefinements
  using SymbolRefinements

  include PgSearch::Model # PostgreSQL-specific text search

  # When did we add met_justification_required?
  STATIC_ANALYSIS_JUSTIFICATION_REQUIRED_DATE =
    Time.iso8601('2017-04-25T00:00:00Z')

  # When did we first show an explicit license for the data
  # (CC-BY-3.0+)?
  ENTRY_LICENSE_EXPLICIT_DATE = Time.iso8601('2017-02-20T12:00:00Z')

  # When did we switch to CDLA-Permissive-2.0?
  ENTRY_LICENSE_CDLA_PERMISSIVE_20_DATE = Time.iso8601('2024-08-23T12:00:00Z')

  STATUS_CHOICE = %w[? Met Unmet].freeze
  STATUS_CHOICE_NA = (STATUS_CHOICE + %w[N/A]).freeze
  MIN_SHOULD_LENGTH = 5
  MAX_TEXT_LENGTH = 8192 # Arbitrary maximum to reduce abuse
  MAX_SHORT_STRING_LENGTH = 254 # Arbitrary maximum to reduce abuse

  # All badge level internal names *including* in_progress
  # NOTE: If you add a new level, modify compute_tiered_percentage
  BADGE_LEVELS = %w[in_progress passing silver gold].freeze

  # All badge level internal names that indicate *completion*,
  # so COMPLETED_BADGE_LEVELS[0] is 'passing'.
  # Note: This is the *internal* lowercase name, e.g., for field names.
  # For *printed* names use t("projects.form_early.level.#{level}")
  # Note that drop() does NOT mutate the original value.
  COMPLETED_BADGE_LEVELS = BADGE_LEVELS.drop(1).freeze

  # All badge levels as IDs. Useful for enumerating "all levels" as:
  # Project::LEVEL_IDS.each do |level| ... end
  LEVEL_ID_NUMBERS = (0..(COMPLETED_BADGE_LEVELS.length - 1))
  LEVEL_IDS = LEVEL_ID_NUMBERS.map(&:to_s)

  PROJECT_OTHER_FIELDS = %i[
    name description homepage_url repo_url cpe implementation_languages
    license general_comments user_id lock_version
    level additional_rights_changes
  ].freeze
  PROJECT_USER_ID_REPEAT = %i[user_id_repeat].freeze # Repeat to change owner
  ALL_CRITERIA_STATUS = Criteria.all.map(&:status).freeze
  ALL_CRITERIA_JUSTIFICATION = Criteria.all.map(&:justification).freeze
  PROJECT_PERMITTED_FIELDS = (PROJECT_OTHER_FIELDS + ALL_CRITERIA_STATUS +
                              ALL_CRITERIA_JUSTIFICATION +
                              PROJECT_USER_ID_REPEAT).freeze

  default_scope { order(:created_at) }

  scope :created_since, ->(time) { where(created_at: time..) }

  scope :gteq, ->(floor) { where(tiered_percentage: floor.to_i..) }

  scope :in_progress, -> { lteq(99) }

  scope :lteq, ->(ceiling) { where(tiered_percentage: ..ceiling.to_i) }

  scope :passing, -> { gteq(100) }

  scope :recently_updated, (
    lambda do
      # The "includes" here isn't ideal.
      # Originally we used "eager_load" on :user, but
      # "eager_load" forces a load of *all* fields per a bug in Rails:
      # https://github.com/rails/rails/issues/15185
      # Switching to ".includes" fixes the bug, though it means we do 2
      # database queries instead of just one.
      # We could use the gem "rails_select_on_includes" to fix this bug:
      # https://github.com/alekseyl/rails_select_on_includes
      # but that's something of a hack.
      # If a totally-cached feed is used, then the development environment
      # will complain as follows:
      # GET /feed
      # AVOID eager loading detected
      #   Project => [:user]
      #   Remove from your finder: :includes => [:user]
      # However, you *cannot* simply remove the includes, because
      # when the feed is *not* completely cached, the code *does* need
      # this user data.
      limit(50).reorder(updated_at: :desc, id: :asc).includes(:user)
    end
  )

  # prefix query (old search system)
  scope :text_search, (
    lambda do |text|
      start_text = "#{sanitize_sql_like(text)}%"
      where(
        Project.arel_table[:name].matches(start_text).or(
          Project.arel_table[:homepage_url].matches(start_text)
        ).or(
          Project.arel_table[:repo_url].matches(start_text)
        )
      )
    end
  )

  # Search for exact match on URL
  # (home page, repo, and maybe package URL someday)
  # We have indexes on each of these columns, so this will be fast.
  # We remove trailing space and slash to make it quietly "work as expected".
  scope :url_search, (
    lambda do |url|
      clean_url = url.chomp(' ').chomp('/')
      where('homepage_url = ? OR repo_url = ?', clean_url, clean_url)
    end
  )

  # Use PostgreSQL-specific text search mechanism
  # There are many options we aren't currently using; for more info, see:
  # https://github.com/Casecommons/pg_search
  pg_search_scope(
    :search_for,
    against: %i[name homepage_url repo_url description]
    # using: { tsearch: { any_word: true } }
  )

  scope :updated_since, ->(time) { where(updated_at: time..) }

  # Record information about a project.
  # We'll also record previous versions of information:
  has_paper_trail

  before_save :update_badge_percentages, unless: :skip_callbacks

  # A project is associated with a user
  belongs_to :user
  delegate :name, to: :user, prefix: true # Support "user_name"
  delegate :nickname, to: :user, prefix: true # Support "user_nickname"

  # For these fields we'll have just simple validation rules.
  # We'll rely on Rails' HTML escaping system to counter XSS.
  validates :name, length: { maximum: MAX_SHORT_STRING_LENGTH }, text: true
  validates :description, length: { maximum: MAX_TEXT_LENGTH }, text: true
  validates :license, length: { maximum: MAX_SHORT_STRING_LENGTH }, text: true
  validates :general_comments, text: true

  # We'll do automated analysis on these URLs, which means we will *download*
  # from URLs provided by untrusted users.  Thus we'll add additional
  # URL restrictions to counter tricks like http://ACCOUNT:PASSWORD@host...
  # and http://something/?arbitrary_parameters

  validates :repo_url, url: true, length: { maximum: MAX_SHORT_STRING_LENGTH },
                       uniqueness: { allow_blank: true }
  validates :homepage_url,
            url: true,
            length: { maximum: MAX_SHORT_STRING_LENGTH }
  validate :need_a_base_url

  # Comma-separated list.  This is very generous in what characters it
  # allows in a programming language name, but restricts it to ASCII and omits
  # problematic characters that are very unlikely in a name like
  # <, >, &, ", brackets, and braces.  This handles language names like
  # JavaScript, C++, C#, D-, and PL/I.  A space is optional after a comma.
  # We have to allow embedded spaces, e.g., "Jupyter Notebook".
  VALID_LANGUAGE_LIST =
    %r{\A(|-| ([A-Za-z0-9!\#$%'()*+.\/\:;=?@\[\]^~ -]+
        (,\ ?[A-Za-z0-9!\#$%'()*+.\/\:;=?@\[\]^~ -]+)*))\Z}x
  validates :implementation_languages,
            length: { maximum: MAX_SHORT_STRING_LENGTH },
            format: {
              with: VALID_LANGUAGE_LIST,
              message: :comma_separated_list
            }

  validates :cpe,
            length: { maximum: MAX_SHORT_STRING_LENGTH },
            format: {
              with: /\A(cpe:.*)?\Z/,
              message: :begin_with_cpe
            }

  validates :user_id,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1
            }

  Criteria.each_value do |criteria|
    criteria.each_value do |criterion|
      if criterion.na_allowed?
        validates criterion.name.status, inclusion: { in: STATUS_CHOICE_NA }
      else
        validates criterion.name.status, inclusion: { in: STATUS_CHOICE }
      end
      validates criterion.name.justification,
                length: { maximum: MAX_TEXT_LENGTH },
                text: true
    end
  end

  # Return a string representing the additional rights on this project.
  # Currently it's just a (possibly empty) list of user ids from
  # AdditionalRight.  If AdditionalRights gains different kinds of rights
  # (e.g., to spec additional owners), this method will need to be tweaked.
  # Returns string representation of additional rights user IDs for this project.
  # @return [String] sorted array of user IDs as string
  def additional_rights_to_s
    # "distinct" shouldn't be needed; it's purely defensive here
    list = AdditionalRight.for_project(id).distinct.pluck(:user_id)
    list.sort.to_s # Use list.sort.to_s[1..-2] to remove surrounding [ and ]
  end

  # Returns string representing badge level based on tiered_percentage.
  # Assumes tiered_percentage is correct. Returns 'in_progress' if not passing yet.
  # See method badge_level if you want 'in_progress' for < 100.
  # See method badge_value if you want the specific percentage for in_progress.
  # @return [String] badge level ('in_progress', 'passing', 'silver', or 'gold')
  def badge_level
    # This is *integer* division, so it truncates.
    BADGE_LEVELS[tiered_percentage / 100]
  end

  # Calculates badge percentage for a specific level.
  # @param level [String, Integer] the badge level to calculate for
  # @return [Integer] percentage (0-100) of criteria met for this level
  def calculate_badge_percentage(level)
    active = Criteria.active(level)
    met = active.count { |criterion| enough?(criterion) }
    to_percentage met, active.size
  end

  # Checks if text contains a URL anywhere in the (justification) text.
  # Note: This regex needs to be logically the same as the one used in the
  # client-side badge calculation, or it may confuse some users.
  # See app/assets/javascripts/*.js function "containsURL".
  #
  # Note that we do NOT need to validate these URLs, because the BadgeApp
  # 1. escapes these (as part of normal processing) against XSS attacks, and
  # 2. does not traverse these URLs in its automated processing.
  # Thus, this rule is intentionally *not* strict at all.  Contrast this
  # with the intentionally strict validation of the project and repo URLs,
  # which *are* traversed by BadgeApp and thus need to be much more strict.
  #
  # @param text [String, nil] the text to check for URLs
  # @return [Boolean] true if text contains a URL matching the pattern
  def contains_url?(text)
    return false if !text || text.start_with?('// ')

    text =~ %r{https?://[^ ]{5}}
  end

  # Returns symbol indicating the status of a particular criterion in this project.
  # Return values:
  # - :criterion_passing - 'Met' (or 'N/A' if applicable) selected with required justification
  # - :criterion_failing - 'Unmet' selected for a MUST criterion
  # - :criterion_barely - 'Unmet' selected for SHOULD/SUGGESTED with required justification
  # - :criterion_url_required - 'Met' selected but required URL missing in justification
  # - :criterion_justification_required - Required justification missing for selection
  # - :criterion_unknown - Criterion left at default value
  #
  # This method is mirrored in assets/project-form.js as getCriterionResult.
  # If you change this method, change getCriterionResult accordingly.
  # @param criterion [Criteria] the criterion to evaluate
  # @return [Symbol] status symbol indicating criterion state
  def get_criterion_result(criterion)
    status = self[criterion.name.status]
    justification = self[criterion.name.justification]
    return :criterion_unknown if status.unknown?
    return get_met_result(criterion, justification) if status.met?
    return get_unmet_result(criterion, justification) if status.unmet?

    get_na_result(criterion, justification)
  end

  # Returns satisfaction data for a specific level and panel.
  # @param level [String, Integer] the badge level
  # @param panel [String] the panel name to filter criteria
  # @return [Hash] hash with :text and :color keys for satisfaction display
  def get_satisfaction_data(level, panel)
    total =
      Criteria[level].values.select do |criterion|
        criterion.major.downcase.delete(' ') == panel
      end
    passing = total.count { |criterion| enough?(criterion) }
    {
      text: "#{passing}/#{total.size}",
      color: get_color(passing / [1, total.size.to_f].max)
    }
  end

  # Returns the badge value: 0..99 (percentage) if in progress,
  # else returns 'passing', 'silver', or 'gold'.
  # Presumes that tiered_percentage has already been calculated.
  # See method badge_level if you want 'in_progress' for < 100.
  # @return [Integer, String] percentage (0-99) or badge level string
  def badge_value
    if tiered_percentage < 100
      tiered_percentage
    else
      # This is *integer* division, so it truncates.
      BADGE_LEVELS[tiered_percentage / 100]
    end
  end

  # Returns this project's image src URL for its badge image (SVG).
  # - If project entry changed recently: returns /badge_static value for immediate accuracy
  # - If project entry NOT changed recently: returns /projects/:id/badge for correct README usage
  # This ensures users see correct results while encouraging proper URL usage.
  # @return [String] URL path for the badge image
  def badge_src_url
    if updated_at > 24.hours.ago # Has this entry changed relatively recently?
      "/badge_static/#{badge_value}"
    else
      "/projects/#{id}/badge"
    end
  end

  # Checks if user should be notified to update static_analysis criterion.
  # Flashes message if user is updating for the first time since we added
  # met_justification_required to that criterion.
  # @param level [String, Integer] the badge level to check
  # @return [Boolean] true if notification should be shown
  def notify_for_static_analysis?(level)
    status = self[Criteria[level][:static_analysis].name.status]
    result = get_criterion_result(Criteria[level][:static_analysis])
    updated_at < STATIC_ANALYSIS_JUSTIFICATION_REQUIRED_DATE &&
      status.met? && result == :criterion_justification_required
  end

  # Sends owner an email when they add a new project.
  # @return [Mail::Message] the delivered email message
  def send_new_project_email
    ReportMailer.email_new_project_owner(self).deliver_now
  end

  # Checks if we should show an explicit license for the data.
  # Old entries did not set a license; we only show entry licenses
  # if the updated_at field indicates there was agreement to it.
  # @return [Boolean] true if entry license should be displayed
  def show_entry_license?
    updated_at >= ENTRY_LICENSE_EXPLICIT_DATE
  end

  # Checks if we should show CDLA-Permissive-2.0 license.
  # @return [Boolean] true if CDLA-Permissive-2.0 license should be displayed
  def show_cdla_permissive_20_license?
    updated_at >= ENTRY_LICENSE_CDLA_PERMISSIVE_20_DATE
  end

  # Determines which field to display for the data license.
  # Uses the project's last updated_at value to return the name of the
  # field in i18n "projects.show" to display as the license.
  # @return [String] i18n field name for the appropriate license
  def data_license_field
    if show_cdla_permissive_20_license?
      'cdla_permissive_20_html'
    elsif show_entry_license?
      'cc_by_3plus_html'
    else
      # This is older data and the user didn't indicate anything,
      # so the "terms of use" of CII apply, which said that unless
      # otherwise noted it's released under CC-BY-3.0 only.
      'cc_by_3only_html'
    end
  end

  # Updates the badge percentage for a given level and relevant event datetime.
  # Level is expressed as a number (0=passing). Presumes lower-level percentages
  # are already calculated if relevant.
  # @param level [String, Integer] the badge level (0=passing, 1=silver, 2=gold)
  # @param current_time [Time] the current time for timestamp updates
  # @return [void]
  def update_badge_percentage(level, current_time)
    old_badge_percentage = self[:"badge_percentage_#{level}"]
    update_prereqs(level) if level.to_i.nonzero?
    self[:"badge_percentage_#{level}"] =
      calculate_badge_percentage(level)
    update_passing_times(level, old_badge_percentage, current_time)
  end

  # Computes the 'tiered percentage' value 0..300.
  # Gives partial credit, but only if you've completed a previous level.
  # @return [Integer] tiered percentage (0-99, 100-199, or 200-299)
  def compute_tiered_percentage
    if badge_percentage_0 < 100
      badge_percentage_0
    elsif badge_percentage_1 < 100
      badge_percentage_1 + 100
    else
      badge_percentage_2 + 200
    end
  end

  # Updates the tiered_percentage field with computed value.
  # @return [Integer] the updated tiered percentage
  def update_tiered_percentage
    self.tiered_percentage = compute_tiered_percentage
  end

  # Updates the badge percentages for all levels.
  # Creates a single datetime value for consistency across all level updates.
  # @return [void]
  def update_badge_percentages
    # Create a single datetime value so that they are consistent
    current_time = Time.now.utc
    Project::LEVEL_IDS.each do |level|
      update_badge_percentage(level, current_time)
    end
    update_tiered_percentage # Update the 'tiered_percentage' number 0..300
  end

  # Returns owning user's name for display purposes.
  # @return [String, nil] user name or nickname for display
  def user_display_name
    user_name || user_nickname
  end

  # Updates badge percentages for all project entries and sends emails
  # for any project where this causes loss or gain of a badge.
  # Use this after badging rules have changed. We precalculate and store
  # percentages in the database for speed, but rule changes don't automatically
  # update the precalculated values.
  # @param levels [Array<String>] array of levels to update
  # @raise [TypeError] if levels is not an Array
  # @raise [ArgumentError] if any level is invalid
  # @return [void]
  # rubocop:disable Metrics/MethodLength
  def self.update_all_badge_percentages(levels)
    raise TypeError, 'levels must be an Array' unless levels.is_a?(Array)

    levels.each do |l|
      raise ArgumentError, "Invalid level: #{l}" unless l.in? Criteria.keys
    end
    Project.skip_callbacks = true
    Project.find_each do |project|
      project.with_lock do
        # Create a single datetime value so that they are consistent
        current_time = Time.now.utc
        levels.each do |level|
          project.update_badge_percentage(level, current_time)
        end
        project.update_tiered_percentage
        project.save!(touch: false)
      end
    end
    Project.skip_callbacks = false
  end
  # rubocop:enable Metrics/MethodLength

  # The following configuration options are trusted.  Set them to
  # reasonable numbers or accept the defaults.

  # Maximum number of reminders to send by email at one time.
  # We want a rate limit to avoid being misinterpreted as a spammer,
  # and also to limit damage if there's a mistake in the code.
  # By default, start very low until we're confident in the code.
  MAX_REMINDERS = (ENV['BADGEAPP_MAX_REMINDERS'] || 2).to_i

  # Minimum number of days since last lost a badge before sending reminder,
  # if it lost one.
  LOST_PASSING_REMINDER = (ENV['BADGEAPP_LOST_PASSING_REMINDER'] || 30).to_i

  # Minimum number of days since project last updated before sending reminder
  LAST_UPDATED_REMINDER = (ENV['BADGEAPP_LAST_UPDATED_REMINDER'] || 30).to_i

  # Minimum number of days since project was last sent a reminder
  LAST_SENT_REMINDER = (ENV['BADGEAPP_LAST_SENT_REMINDER'] || 60).to_i

  # Returns projects that should be reminded to work on their badges.
  # See: https://github.com/coreinfrastructure/best-practices-badge/issues/487
  # Selects in-progress projects that are inactive, not recently reminded,
  # have valid email, and owner accepts emails. Uses single database query.
  # @return [ActiveRecord::Relation] projects eligible for reminders
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.projects_to_remind
    # This is computed entirely using the ActiveRecord query interface
    # as a single select+sort+limit, and not implemented using methods or
    # direct SQL commands. Using the ActiveRecord query interface will turn
    # this directly into a single database request, which will be blazingly
    # fast regardless of the database size (via the indexes). Method
    # invocations would be super-slow, and direct SQL commands will be less
    # portable than ActiveRecord's interface (which works to paper over
    # differences between SQL engines).
    #
    # Select projects eligible for reminders =
    #   in_progress and not_recently_lost_badge
    #   and inactive and not_recently_reminded and valid_email
    #   and owner_accepts_emails.
    # where these terms are defined as:
    #   in_progress = badge_percentage less than 100%.
    #   not_recently_lost_badge = lost_passing_at IS NULL OR
    #     less than LOST_PASSING_REMINDER (30) days ago
    #   inactive = updated_at is LAST_UPDATED_REMINDER (30) days ago or more
    #   not_recently_reminded = last_reminder_at IS NULL OR
    #     more than 60 days ago. Notice that if recently_reminded is null
    #     (no reminders have been sent), only the other criteria matter.
    #   valid_email = users.encrypted_email (joined) is not null
    #   owner_accepts_emails = users.notification_emails is true
    # Prioritize. Sort by the last_reminder_at datetime
    #   (use updated_at if last_reminder_at is null), oldest first.
    #   Since last_reminder_at gets updated with a newer datetime when
    #   we send a message, each email we send will lower its reminder
    #   priority. Thus we will eventually cycle through all inactive projects
    #   if none of them respond to reminders.
    #   Use: projects.order("COALESCE(last_reminder_at, updated_at)")
    #   We cannot check if email includes "@" here, because they are
    #   encrypted (the database does not have access to the keys, by intent).
    #
    # The "reorder" below uses "Arel.sql" to work around
    # a deprecation warning from Rails 5.2, and
    # is not expected to work in Rails 6.  The warning is as follows:
    # DEPRECATION WARNING: Dangerous query method
    # (method whose arguments are used as raw SQL) called with
    # non-attribute argument(s): "COALESCE(last_reminder_at,
    # projects.updated_at)". Non-attribute arguments will be
    # disallowed in Rails 6.0. This method should not be called with
    # user-provided values, such as request parameters or model
    # attributes. Known-safe values can be passed by wrapping
    # them in Arel.sql().
    # For now we'll wrap them as required.  This is unfortunate; it would
    # dangerous if user-provided data was used, but that is not the case.
    # We're hoping Rails 6 will give us an alternative construct.
    # If not, alternatives include creating a calculated field
    # (e.g., one that does the coalescing).
    Project
      .select('projects.*, users.encrypted_email as user_encrypted_email')
      .where('badge_percentage_0 < 100')
      .where('lost_passing_at IS NULL OR lost_passing_at < ?',
             LOST_PASSING_REMINDER.days.ago)
      .where(projects: { updated_at: ...LAST_UPDATED_REMINDER.days.ago })
      .where('last_reminder_at IS NULL OR last_reminder_at < ?',
             LAST_SENT_REMINDER.days.ago)
      .joins(:user).references(:user) # Need this to check email address
      .where('user_id IS NOT NULL') # Safety check
      .where('users.encrypted_email IS NOT NULL')
      .where(users: { notification_emails: true })
      .reorder(Arel.sql('COALESCE(last_reminder_at, projects.updated_at)'))
      .first(MAX_REMINDERS)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Return which projects should be announced as getting badges in the
  # month target_month with level (as a number, 0=passing)
  def self.projects_first_in(level, target_month)
    # Defense-in-depth: ensure 'level' is a valid value.
    return unless LEVEL_ID_NUMBERS.member?(level)

    name = COMPLETED_BADGE_LEVELS[level] # level name, e.g. 'passing'
    # We could omit listing projects which have lost & regained their
    # badge by adding this line:
    # .where('lost_#{name}_at IS NULL')
    # However, it seems reasonable to note projects that have lost their
    # badge but have since regained it (especially since it could have
    # happened within this month!). After all, we want to encourage
    # projects that have lost their badge levels to regain them.
    Project
      .select("id, name, achieved_#{name}_at")
      .where("badge_percentage_#{level} >= 100")
      .where("achieved_#{name}_at >= ?", target_month.at_beginning_of_month)
      .where("achieved_#{name}_at <= ?", target_month.at_end_of_month)
      .reorder("achieved_#{name}_at")
  end

  def self.recently_reminded
    Project
      .select('projects.*, users.encrypted_email as user_encrypted_email')
      .joins(:user).references(:user) # Need this to check email address
      .where('last_reminder_at IS NOT NULL')
      .where(last_reminder_at: 14.days.ago..)
      .reorder('last_reminder_at')
  end

  # Purges data about this project from the CDN if any exists.
  # @return [void]
  def purge_cdn_project
    cdn_badge_key = record_key
    FastlyRails.purge_by_key cdn_badge_key
  end

  WHAT_IS_ENOUGH = %i[criterion_passing criterion_barely].freeze

  private

  # def all_active_criteria_passing?
  #   Criteria.active.all? { |criterion| enough? criterion }
  # end

  # Checks if criterion result is sufficient (passing or barely passing).
  # This method is mirrored in assets/project-form.js as isEnough.
  # If you change this method, change isEnough accordingly.
  # @param criterion [Criteria] the criterion to check
  # @return [Boolean] true if criterion is sufficient
  def enough?(criterion)
    result = get_criterion_result(criterion)
    WHAT_IS_ENOUGH.include?(result)
  end

  # Returns HSL color value based on completion percentage.
  # This method is mirrored in assets/project-form.js as getColor.
  # If you change this method, change getColor accordingly.
  # @param value [Float] completion percentage (0.0 to 1.0)
  # @return [String] HSL color string
  def get_color(value)
    hue = (value * 120).round
    "hsl(#{hue}, 100%, 50%)"
  end

  # This method is mirrored in assets/project-form.js as getMetResult
  # If you change this method, change getMetResult accordingly.
  def get_met_result(criterion, justification)
    return :criterion_url_required if criterion.met_url_required? &&
                                      !contains_url?(justification)
    return :criterion_justification_required if
      criterion.met_justification_required? &&
      !justification_good?(justification)

    :criterion_passing
  end

  # This method is mirrored in assets/project-form.js as getNAResult
  # If you change this method, change getNAResult accordingly.
  def get_na_result(criterion, justification)
    return :criterion_justification_required if
      criterion.na_justification_required? &&
      !justification_good?(justification)

    :criterion_passing
  end

  # This method is mirrored in assets/project-form.js as getUnmetResult
  # If you change this method, change getUnmetResult accordingly.
  def get_unmet_result(criterion, justification)
    return :criterion_barely if criterion.suggested? || (criterion.should? &&
                               justification_good?(justification))
    return :criterion_justification_required if criterion.should?

    :criterion_failing
  end

  def justification_good?(justification)
    return false if justification.nil? || justification.start_with?('// ')

    justification.length >= MIN_SHOULD_LENGTH
  end

  def need_a_base_url
    return if repo_url.present? || homepage_url.present?

    errors.add :base, I18n.t('error_messages.need_home_page_or_url')
  end

  def to_percentage(portion, total)
    return 0 if portion.zero?
    return 100 if portion >= total

    # Give percentage, but only up to 99% (so "100%" always means "complete")
    # The tertiary operator is clearer & faster than using [...].min
    result = ((portion * 100.0) / total).round
    [result, 99].min
  end

  # Update achieved_..._at & lost_..._at fields given level as number
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def update_passing_times(level, old_badge_percentage, current_time)
    level_name = COMPLETED_BADGE_LEVELS[level.to_i] # E.g., 'passing'
    current_percentage = self[:"badge_percentage_#{level}"]
    # If something is wrong, don't modify anything!
    return if current_percentage.blank? || old_badge_percentage.blank?

    current_percentage_i = current_percentage.to_i
    old_badge_percentage_i = old_badge_percentage.to_i
    if current_percentage_i >= 100 && old_badge_percentage_i < 100
      self[:"achieved_#{level_name}_at"] = current_time
      first_achieved_field = :"first_achieved_#{level_name}_at"
      if self[first_achieved_field].blank? # First time? Set that too!
        self[first_achieved_field] = current_time
      end
    elsif current_percentage_i < 100 && old_badge_percentage_i >= 100
      self[:"lost_#{level_name}_at"] = current_time
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  # Given numeric level 1+, set the value of
  # achieve_{previous_level_name}_status to either Met or Unmet, based on
  # the achievement of the *previous* level. This is a simple way to ensure
  # that to pass level X when X > 0, you must meet the criteria of level X-1.
  # We *only* set the field if it currently has a different value.
  # When filling in the prerequisites, we do not fill in the justification
  # for them. The justification is only there as it makes implementing this
  # portion of the code simpler.
  def update_prereqs(level)
    level = level.to_i
    return if level <= 0

    # The following works because BADGE_LEVELS[1] is 'passing', etc:
    achieved_previous_level = :"achieve_#{BADGE_LEVELS[level]}_status"

    if self[:"badge_percentage_#{level - 1}"] >= 100
      return if self[achieved_previous_level] == 'Met'

      self[achieved_previous_level] = 'Met'
    else
      return if self[achieved_previous_level] == 'Unmet'

      self[achieved_previous_level] = 'Unmet'
    end
  end
end
# rubocop:enable Metrics/ClassLength
