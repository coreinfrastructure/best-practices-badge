# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
class Project < ActiveRecord::Base
  using StringRefinements
  using SymbolRefinements

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
    license general_comments user_id
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

  scope :text_search, (
    lambda do |text|
      start_text = "#{text}%"
      where(
        Project.arel_table[:name].matches(start_text).or(
          Project.arel_table[:homepage_url].matches(start_text)
        ).or(
          Project.arel_table[:repo_url].matches(start_text)
        )
      )
    end
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

  def update_badge_percentage
    self.badge_percentage = calculate_badge_percentage
  end

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
