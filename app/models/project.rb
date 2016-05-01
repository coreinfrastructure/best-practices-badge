# frozen_string_literal: true
class Project < ActiveRecord::Base
  using SymbolRefinements

  # Ransack needs an "ActiveRecord"-like object for populating the dropdown,
  # or it won't do its query generation magic.
  class BadgeStatus
    attr_reader :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  BADGE_STATUS_CHOICE = [BadgeStatus.new(nil, nil),
                         BadgeStatus.new('in_progress', 'in progress'),
                         BadgeStatus.new('passing', 'passing'),
                         BadgeStatus.new('failing', 'failing')].freeze
  STATUS_CHOICE = %w(? Met Unmet).freeze
  STATUS_CHOICE_NA = (STATUS_CHOICE + %w(N/A)).freeze
  MIN_SHOULD_LENGTH = 5
  MAX_TEXT_LENGTH = 8192 # Arbitrary maximum to reduce abuse
  MAX_SHORT_STRING_LENGTH = 254 # Arbitrary maximum to reduce abuse

  PROJECT_OTHER_FIELDS = %i(name description homepage_url cpe
                            license general_comments user_id).freeze
  ALL_CRITERIA_STATUS = Criteria.map { |c| c.name.status }.freeze
  ALL_CRITERIA_JUSTIFICATION = Criteria.map { |c| c.name.justification }.freeze
  PROJECT_PERMITTED_FIELDS = (PROJECT_OTHER_FIELDS + ALL_CRITERIA_STATUS +
                              ALL_CRITERIA_JUSTIFICATION).freeze

  # A project is associated with a user
  belongs_to :user
  delegate :name, to: :user, prefix: true

  default_scope { order(:created_at) }

  # Record information about a project.
  # We'll also record previous versions of information:
  has_paper_trail

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

  before_save :update_badge_status

  # Validate all of the criteria-related inputs
  Criteria.each do |criterion|
    if criterion.na_allowed?
      validates criterion.name.status, inclusion: { in: STATUS_CHOICE_NA }
    else
      validates criterion.name.status, inclusion: { in: STATUS_CHOICE }
    end
    validates criterion.name.justification, length: { maximum: MAX_TEXT_LENGTH }
  end

  def update_badge_status
    self.badge_status = badge_level
  end

  def badge_level
    return 'in_progress' if any_status_in_progress?
    return 'passing' if all_active_criteria_passing?
    'failing'
  end

  def badge_percentage
    met = Criteria.active.count { |criterion| passing? criterion }
    to_percentage met, Criteria.active.length
  end

  def contains_url?(text)
    text =~ /#{URI.regexp(%w(http https))}/
  end

  private

  def all_active_criteria_passing?
    Criteria.active.all? { |criterion| passing? criterion }
  end

  def any_status_in_progress?
    Criteria.active.any? do |criterion|
      self[criterion.name.status] == '?' || self[criterion.name.status].blank?
    end
  end

  def need_a_base_url
    return unless repo_url.blank? && homepage_url.blank?
    errors.add :base, 'Need at least a home page or repository URL'
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def passing?(criterion)
    status = self[criterion.name.status]
    justification = self[criterion.name.justification]
    category = criterion.category
    met_needs_url = criterion.met_url_required?

    return true if status == 'N/A'
    return true if status == 'Met' && !met_needs_url
    return true if status == 'Met' && contains_url?(justification)
    return true if category == 'SHOULD' && status == 'Unmet' &&
                   justification.length >= MIN_SHOULD_LENGTH
    return true if category == 'SUGGESTED' && status != '?'
    false
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

  def to_percentage(portion, total)
    return 0 if portion.zero?
    ((portion * 100.0) / total).round
  end
end
