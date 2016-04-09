# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
class Project < ActiveRecord::Base
  STATUS_CHOICE = %w(? Met Unmet).freeze
  STATUS_CHOICE_NA = (STATUS_CHOICE + %w(N/A)).freeze
  MIN_SHOULD_LENGTH = 5
  MAX_TEXT_LENGTH = 8192 # Arbitrary maximum to reduce abuse
  MAX_SHORT_STRING_LENGTH = 254 # Arbitrary maximum to reduce abuse

  # The "Criteria" hash is loaded during application initialization
  # from a YAML file.

  ALL_CRITERIA = Criteria.keys.map(&:to_sym).freeze
  ALL_ACTIVE_CRITERIA = ALL_CRITERIA.reject do |criterion|
    Criteria[criterion][:category] == 'FUTURE'
  end.freeze
  ALL_CRITERIA_STATUS = ALL_CRITERIA.map(&:status).freeze
  ALL_CRITERIA_JUSTIFICATION = ALL_CRITERIA.map(&:justification).freeze
  PROJECT_OTHER_FIELDS = %i(name description project_homepage_url repo_url cpe
                            license general_comments user_id).freeze
  PROJECT_PERMITTED_FIELDS = (PROJECT_OTHER_FIELDS + ALL_CRITERIA_STATUS +
                              ALL_CRITERIA_JUSTIFICATION).freeze

  # TODO: Remove these Criteria queries from the project model
  # Note: These are up top because they must be defined before use

  # Is this criterion in the category MUST, SHOULD, or SUGGESTED?
  def self.criterion_category(criterion)
    (Criteria[criterion])[:category]
  end

  # Is a URL required in the justification to be enough with met?
  def self.met_url_required?(criterion)
    (Criteria[criterion])[:met_url_required]
  end

  # Is na allowed?
  def self.na_allowed?(criterion)
    (Criteria[criterion])[:na_allowed]
  end

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
  validates :project_homepage_url,
            url: true,
            length: { maximum: MAX_SHORT_STRING_LENGTH }
  validate :need_a_base_url

  validates :cpe,
            length: { maximum: MAX_SHORT_STRING_LENGTH },
            format: { with: /\A(cpe:.*)?\Z/, message: 'Must begin with cpe:' }

  validates :user_id, presence: true

  # Validate all of the criteria-related inputs
  ALL_CRITERIA.each do |criterion|
    if na_allowed?(criterion)
      validates criterion.status, inclusion: { in: STATUS_CHOICE_NA }
    else
      validates criterion.status, inclusion: { in: STATUS_CHOICE }
    end
    validates criterion.justification, length: { maximum: MAX_TEXT_LENGTH }
  end

  def badge_level
    if any_status_in_progress?
      'in_progress'
    elsif all_active_criteria_passing?
      'passing'
    else 'failing'
    end
  end

  def badge_percentage
    met = ALL_ACTIVE_CRITERIA.count { |criterion| passing? criterion }
    to_percentage met, ALL_ACTIVE_CRITERIA.length
  end

  private

  def any_status_in_progress?
    ALL_ACTIVE_CRITERIA.any? do |criterion|
      self[criterion.status] == '?' || self[criterion.status].blank?
    end
  end

  def all_active_criteria_passing?
    ALL_ACTIVE_CRITERIA.all? { |criterion| passing? criterion }
  end

  # TODO: define standard URL regex, then use everywhere.
  def contains_url?(text)
    return false if text.nil?
    text.match %r(https?://[^ ]{5,})
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def passing?(criterion)
    status = self[criterion.status]
    justification = self[criterion.justification]
    category = Project.criterion_category(criterion)
    met_needs_url = Project.met_url_required?(criterion)

    return true if category == 'FUTURE'
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

  def need_a_base_url
    return unless repo_url.blank? && project_homepage_url.blank?
    errors.add :base, 'Need at least a project or repository URL'
  end

  def to_percentage(portion, total)
    if portion == total
      100
    elsif portion == 0
      0
    else
      ((portion * 100.0) / total).round
    end
  end
end
