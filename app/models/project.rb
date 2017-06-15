# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/ClassLength
class Project < ApplicationRecord
  has_many :additional_rights
  # We could add something like this:
  # + has_many :users, through: :additional_rights
  # but we don't, because we don't use the other information about those users.
  # We only need the user_ids and the additional_rights table has that.

  using StringRefinements
  using SymbolRefinements

  include PgSearch # PostgreSQL-specific text search

  STATUS_CHOICE = %w[? Met Unmet].freeze
  STATUS_CHOICE_NA = (STATUS_CHOICE + %w[N/A]).freeze
  MIN_SHOULD_LENGTH = 5
  MAX_TEXT_LENGTH = 8192 # Arbitrary maximum to reduce abuse
  MAX_SHORT_STRING_LENGTH = 254 # Arbitrary maximum to reduce abuse

  BADGE_LEVELS = %w[in_progress passing silver gold].freeze

  PROJECT_OTHER_FIELDS = %i[
    name description homepage_url repo_url cpe implementation_languages
    license general_comments user_id disabled_reminders lock_version
    level
  ].freeze
  ALL_CRITERIA_STATUS = Criteria.all.map(&:status).freeze
  ALL_CRITERIA_JUSTIFICATION = Criteria.all.map(&:justification).freeze
  PROJECT_PERMITTED_FIELDS = (PROJECT_OTHER_FIELDS + ALL_CRITERIA_STATUS +
                              ALL_CRITERIA_JUSTIFICATION).freeze

  default_scope { order(:created_at) }

  scope :created_since, (
    lambda do |time|
      where(Project.arel_table[:created_at].gteq(time))
    end
  )

  scope :gteq, (
    lambda do |floor|
      where(Project.arel_table[:badge_percentage_0].gteq(floor.to_i))
    end
  )

  scope :in_progress, -> { lteq(99) }

  scope :lteq, (
    lambda do |ceiling|
      where(Project.arel_table[:badge_percentage_0].lteq(ceiling.to_i))
    end
  )

  scope :passing, -> { gteq(100) }
  # rubocop:enable Lint/AmbiguousBlockAssociation

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

  # Use PostgreSQL-specific text search mechanism
  # There are many options we aren't currently using; for more info, see:
  # https://github.com/Casecommons/pg_search
  pg_search_scope(
    :search_for,
    against: %i[name homepage_url repo_url description]
    # using: { tsearch: { any_word: true } }
  )

  scope :updated_since, (
    lambda do |time|
      where(Project.arel_table[:updated_at].gteq(time))
    end
  )

  # Record information about a project.
  # We'll also record previous versions of information:
  has_paper_trail

  before_save :update_badge_percentages

  # A project is associated with a user
  belongs_to :user
  delegate :name, to: :user, prefix: true # Support "user_name"
  delegate :nickname, to: :user, prefix: true # Support "user_nickname"

  # For these fields we'll have just simple validation rules.
  # We'll rely on Rails' HTML escaping system to counter XSS.
  validates :name, length: { maximum: MAX_SHORT_STRING_LENGTH },
                   text: true
  validates :description, length: { maximum: MAX_TEXT_LENGTH },
                          text: true
  validates :license, length: { maximum: MAX_SHORT_STRING_LENGTH },
                      text: true
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
  VALID_LANGUAGE_LIST = %r{\A(|-|
                          ([A-Za-z0-9!\#$%'()*+.\/\:;=?@\[\]^~-]+
                            (,\ ?[A-Za-z0-9!\#$%'()*+.\/\:;=?@\[\]^~-]+)*))\Z}x
  validates :implementation_languages,
            length: { maximum: MAX_SHORT_STRING_LENGTH },
            format: {
              with: VALID_LANGUAGE_LIST,
              message: I18n.t('error_messages.comma_separated_list')
            }

  validates :cpe,
            length: { maximum: MAX_SHORT_STRING_LENGTH },
            format: {
              with: /\A(cpe:.*)?\Z/,
              message: I18n.t('error_messages.begin_with_cpe')
            }

  validates :user_id, presence: true

  Criteria.each do |_level, criteria|
    criteria.each do |_name, criterion|
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

  # Return string representing badge level; assumes badge_percentage correct.
  def badge_level
    BADGE_LEVELS.each_with_index do |level, index|
      return level if index == Criteria.count
      return level if self["badge_percentage_#{index}".to_sym] < 100
    end
  end

  def calculate_badge_percentage(level)
    active = Criteria.active(level)
    met = active.count { |criterion| enough?(criterion) }
    to_percentage met, active.size
  end

  # Does this contain a URL *anywhere* in the (justification) text?
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
  def contains_url?(text)
    text =~ %r{https?://[^ ]{5}}
  end

  # Returns a symbol indicating a the status of an particular criterion
  # in a project.  These are:
  # :criterion_passing -
  #   'Met' (or 'N/A' if applicable) has been selected for the criterion
  #   and all requred justification text (including url's) have been entered  #
  # :criterion_failing -
  #   'Unmet' has been selected for a MUST criterion'.
  # :criterion_barely -
  #   'Unmet' has been selected for a SHOULD or SUGGESTED criterion and
  #   ,if SHOULD, required justification text has been entered.
  # :criterion_url_required -
  #   'Met' has been selected, but a required url in the justification
  #   text is missing.
  # :criterion_justification_required -
  #   Required justification for 'Met', 'N/A' or 'Unmet' selection is missing.
  # :criterion_unknown -
  #   The criterion has been left at it's default value and thus the status
  #   is unknown.
  # This method is mirrored in assets/project-form.js as getCriterionResult
  # If you change this method, change getCriterionResult accordingly.
  def get_criterion_result(criterion)
    status = self[criterion.name.status]
    justification = self[criterion.name.justification]
    return :criterion_unknown if status.unknown?
    return get_met_result(criterion, justification) if status.met?
    return get_unmet_result(criterion, justification) if status.unmet?
    get_na_result(criterion, justification)
  end

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

  # Flash a message to update static_analysis if the user is updating
  # for the first time since we added met_justification_required that
  # criterion
  STATIC_ANALYSIS_JUSTIFICATION_REQUIRED_DATE =
    DateTime.iso8601('2017-04-25T00:00Z')
  def notify_for_static_analysis?(level)
    status = self[Criteria[level][:static_analysis].name.status]
    result = get_criterion_result(Criteria[level][:static_analysis])
    updated_at < STATIC_ANALYSIS_JUSTIFICATION_REQUIRED_DATE &&
      status.met? && result == :criterion_justification_required
  end

  # Send owner an email they add a new project.
  def send_new_project_email
    ReportMailer.email_new_project_owner(self).deliver_now
  end

  # Return true if we should show an explicit license for the data.
  # Old entries did not set a license; we only want to show entry licenses
  # if the updated_at field indicates there was agreement to it.
  ENTRY_LICENSE_EXPLICIT_DATE = DateTime.iso8601('2017-02-20T12:00Z')
  def show_entry_license?
    updated_at >= ENTRY_LICENSE_EXPLICIT_DATE
  end

  # Update the badge percentage, and update relevant event datetime if needed.
  # This code will need to changed if there are multiple badge levels, or
  # if there are more than 100 criteria. (If > 100 criteria, switch
  # percentage to something like millipercentage.)
  def update_badge_percentages
    Criteria.keys.each do |level|
      old_badge_percentage = self["badge_percentage_#{level}".to_sym]
      self["badge_percentage_#{level}".to_sym] =
        calculate_badge_percentage(level)
      update_passing_times(old_badge_percentage) if level == '0'
    end
  end

  # Return owning user's name for purposes of display.
  def user_display_name
    user_name || user_nickname
  end

  # Update badge percentages for all project entries, and send emails
  # to any project where this causes loss or gain of a badge.
  # Use this after the badging rules have changed.
  # We need this we precalculate and store percentages in the database;
  # this speeds up many actions, but it means that a change in the rules
  # doesn't automatically change the precalculated values.
  # rubocop:disable Metrics/MethodLength, Style/MethodCalledOnDoEndBlock
  def self.update_all_badge_percentages
    Project.find_each do |project|
      project.with_lock do
        old_badge_percentages =
          Criteria.keys.map do |level|
            [level, project["badge_percentage_#{level}".to_sym]]
          end.to_h
        project.update_badge_percentages
        old_badge_percentages.each do |level, percentage|
          unless percentage ==
                 project["badge_percentage_#{level}".to_sym]
            project.save!(touch: false)
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Style/MethodCalledOnDoEndBlock

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

  # Return which projects should be reminded to work on their badges.  See:
  # https://github.com/linuxfoundation/cii-best-practices-badge/issues/487
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
    #   in_progress and not_recently_lost_badge and not_disabled_reminders
    #   and inactive and not_recently_reminded and valid_email.
    # where these terms are defined as:
    #   in_progress = badge_percentage less than 100%.
    #   not_recently_lost_badge = lost_passing_at IS NULL OR
    #     less than LOST_PASSING_REMINDER (30) days ago
    #   not_disabled_reminders = not(project.disabled_reminders), default false
    #   inactive = updated_at is LAST_UPDATED_REMINDER (30) days ago or more
    #   not_recently_reminded = last_reminder_at IS NULL OR
    #     more than 60 days ago. Notice that if recently_reminded is null
    #     (no reminders have been sent), only the other criteria matter.
    #   valid_email = user_id.email (joined) is not null and includes "@"
    # Prioritize. Sort by the last_reminder_at datetime
    #   (use updated_at if last_reminder_at is null), oldest first.
    #   Since last_reminder_at gets updated with a newer datetime when
    #   we send a message, each email we send will lower its reminder
    #   priority. Thus we will eventually cycle through all inactive projects
    #   if none of them respond to reminders.
    #   Use: projects.order("COALESCE(last_reminder_at, updated_at)")
    Project
      .select('projects.*, users.email as user_email')
      .where('badge_percentage_0 < 100')
      .where('lost_passing_at IS NULL OR lost_passing_at < ?',
             LOST_PASSING_REMINDER.days.ago)
      .where('disabled_reminders = FALSE')
      .where('projects.updated_at < ?',
             LAST_UPDATED_REMINDER.days.ago)
      .where('last_reminder_at IS NULL OR last_reminder_at < ?',
             LAST_SENT_REMINDER.days.ago)
      .joins(:user).references(:user) # Need this to check email address
      .where('user_id IS NOT NULL') # Safety check
      .where('users.email IS NOT NULL')
      .where('users.email LIKE \'%@%\'') # We can't send emails without '@'
      .reorder('COALESCE(last_reminder_at, projects.updated_at)')
      .first(MAX_REMINDERS)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Return which projects should be announced as getting badges in the
  # month target_month
  def self.projects_first_passing_in(target_month)
    Project
      .select('id, name, achieved_passing_at')
      .where('badge_percentage_0 = 100')
      .where('achieved_passing_at >= ?', target_month.at_beginning_of_month)
      .where('achieved_passing_at <= ?', target_month.at_end_of_month)
      .where('lost_passing_at IS NULL')
      .reorder('achieved_passing_at')
  end

  def self.recently_reminded
    Project
      .select('projects.*, users.email as user_email')
      .joins(:user).references(:user) # Need this to check email address
      .where('last_reminder_at IS NOT NULL')
      .where('last_reminder_at >= ?', 14.days.ago)
      .reorder('last_reminder_at')
  end

  private

  # def all_active_criteria_passing?
  #   Criteria.active.all? { |criterion| enough? criterion }
  # end

  # This method is mirrored in assets/project-form.js as isEnough
  # If you change this method, change isEnough accordingly.
  def enough?(criterion)
    result = get_criterion_result(criterion)
    result == :criterion_passing || result == :criterion_barely
  end

  # This method is mirrored in assets/project-form.js as getColor
  # If you change this method, change getColor accordingly.
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
    return false if justification.nil?
    justification.length >= MIN_SHOULD_LENGTH
  end

  def need_a_base_url
    return unless repo_url.blank? && homepage_url.blank?
    errors.add :base, I18n.t('error_messages.need_home_page_or_url')
  end

  def update_passing_times(old_badge_percentage)
    if badge_percentage_0 == 100 && old_badge_percentage < 100
      self.achieved_passing_at = Time.now.utc
    elsif badge_percentage_0 < 100 && old_badge_percentage == 100
      self.lost_passing_at = Time.now.utc
    end
  end

  def to_percentage(portion, total)
    return 0 if portion.zero?
    ((portion * 100.0) / total).round
  end
end
