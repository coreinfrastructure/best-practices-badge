# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
class Project < ActiveRecord::Base
  using StringRefinements
  using SymbolRefinements

  include PgSearch # PostgreSQL-specific text search

  BADGE_STATUSES = [
    ['All', nil],
    ['Passing (100%)', 100],
    ['In Progress (25% or more)', 25],
    ['In Progress (50% or more)', 50],
    ['In Progress (75% or more)', 75],
    ['In Progress (90% or more)', 90]
  ].freeze
  STATUS_CHOICE = %w(? Met Unmet).freeze
  STATUS_CHOICE_NA = (STATUS_CHOICE + %w(N/A)).freeze
  MIN_SHOULD_LENGTH = 5
  MAX_TEXT_LENGTH = 8192 # Arbitrary maximum to reduce abuse
  MAX_SHORT_STRING_LENGTH = 254 # Arbitrary maximum to reduce abuse

  PROJECT_OTHER_FIELDS = %i(
    name description homepage_url cpe
    license general_comments user_id disabled_reminders
  ).freeze
  ALL_CRITERIA_STATUS = Criteria.map { |c| c.name.status }.freeze
  ALL_CRITERIA_JUSTIFICATION = Criteria.map { |c| c.name.justification }.freeze
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
      where(Project.arel_table[:badge_percentage].gteq(floor.to_i))
    end
  )

  scope :in_progress, -> { lteq(99) }

  scope :lteq, (
    lambda do |ceiling|
      where(Project.arel_table[:badge_percentage].lteq(ceiling.to_i))
    end
  )

  scope :passing, -> { gteq(100) }

  scope :recently_updated, (
    lambda do
      unscoped.limit(50).order(updated_at: :desc, id: :asc).eager_load(:user)
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
    against: %i(name homepage_url repo_url description)
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

  before_save :update_badge_percentage

  # A project is associated with a user
  belongs_to :user
  delegate :name, to: :user, prefix: true

  # For these fields we'll have just simple validation rules.
  # We'll rely on Rails' HTML escaping system to counter XSS.
  validates :name, length: { maximum: MAX_SHORT_STRING_LENGTH }
  validates :description, length: { maximum: MAX_TEXT_LENGTH }
  validates :license, length: { maximum: MAX_SHORT_STRING_LENGTH }

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

  validates :cpe,
            length: { maximum: MAX_SHORT_STRING_LENGTH },
            format: { with: /\A(cpe:.*)?\Z/, message: 'Must begin with cpe:' }

  validates :user_id, presence: true

  # Validate all of the criteria-related inputs
  Criteria.each do |criterion|
    if criterion.na_allowed?
      validates criterion.name.status, inclusion: { in: STATUS_CHOICE_NA }
    else
      validates criterion.name.status, inclusion: { in: STATUS_CHOICE }
    end
    validates criterion.name.justification, length: { maximum: MAX_TEXT_LENGTH }
  end

  def badge_level
    return 'passing' if all_active_criteria_passing?
    'in_progress'
  end

  def calculate_badge_percentage
    met = Criteria.active.count { |criterion| passing? criterion }
    to_percentage met, Criteria.active.length
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

  # Update the badge percentage, and update relevant event datetime if needed.
  # This code will need to changed if there are multiple badge levels, or
  # if there are more than 100 criteria. (If > 100 criteria, switch
  # percentage to something like millipercentage.)
  def update_badge_percentage
    old_badge_percentage = badge_percentage
    self.badge_percentage = calculate_badge_percentage
    if badge_percentage == 100 && old_badge_percentage < 100
      self.achieved_passing_at = Time.now.utc
    elsif badge_percentage < 100 && old_badge_percentage == 100
      self.lost_passing_at = Time.now.utc
    end
  end

  # Maximum number of reminders to send by email at one time.
  # We want a rate limit to avoid being misinterpreted as a spammer,
  # and also to limit damage if there's a mistake in the code.
  # By default, start very low until we're confident in the code.
  MAX_REMINDERS = (ENV['BADGEAPP_MAX_REMINDERS'] || 2).to_i

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
    #     less than 30 days ago
    #   not_disabled_reminders = not(project.disabled_reminders), default false
    #   inactive = updated_at is 30 days ago or more
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
      .where('badge_percentage < 100')
      .where('lost_passing_at IS NULL OR lost_passing_at < ?', 30.days.ago)
      .where('disabled_reminders = FALSE')
      .where('projects.updated_at < ?', 30.days.ago)
      .where('last_reminder_at IS NULL OR last_reminder_at < ?', 60.days.ago)
      .joins(:user).references(:user) # Need this to check email address
      .where('user_id IS NOT NULL') # Safety check
      .where('users.email IS NOT NULL')
      .where('users.email LIKE \'%@%\'') # We can't send emails without '@'
      .reorder('COALESCE(last_reminder_at, projects.updated_at)')
      .first(MAX_REMINDERS)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def all_active_criteria_passing?
    Criteria.active.all? { |criterion| passing? criterion }
  end

  def need_a_base_url
    return unless repo_url.blank? && homepage_url.blank?
    errors.add :base, 'Need at least a home page or repository URL'
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def passing?(criterion)
    status = self[criterion.name.status]
    justification = self[criterion.name.justification]

    return true if status.na?
    return true if status.met? && !criterion.met_url_required?
    return true if status.met? && contains_url?(justification)
    return true if criterion.should? && status.unmet? &&
                   justification.length >= MIN_SHOULD_LENGTH
    return true if criterion.suggested? && !status.unknown?
    false
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def to_percentage(portion, total)
    return 0 if portion.zero?
    ((portion * 100.0) / total).round
  end
end
