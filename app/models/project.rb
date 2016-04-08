# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
require 'set'
class Project < ActiveRecord::Base
  STATUS_CHOICE = %w(? Met Unmet).freeze
  STATUS_CHOICE_NA = (STATUS_CHOICE + %w(N/A)).freeze
  MIN_SHOULD_LENGTH = 5
  MAX_TEXT_LENGTH = 8192 # Arbitrary maximum to reduce abuse
  MAX_SHORT_STRING_LENGTH = 254 # Arbitrary maximum to reduce abuse

  # The "Criteria" hash is loaded during application initialization
  # from a YAML file.

  ALL_CRITERIA = Criteria.keys.to_set.freeze
  ALL_ACTIVE_CRITERIA = ALL_CRITERIA.select do |criterion|
    Criteria[criterion.to_s]['category'] != 'FUTURE'
  end.to_set.freeze
  ALL_CRITERIA_STATUS = ALL_CRITERIA.map do |criterion|
    "#{criterion}_status".to_sym
  end.to_set.freeze
  ALL_CRITERIA_JUSTIFICATION = ALL_CRITERIA.map do |criterion|
    "#{criterion}_justification".to_sym
  end.to_set.freeze
  PROJECT_OTHER_FIELDS = Set.new(
    [:name, :description, :project_homepage_url, :repo_url, :cpe,
     :license, :general_comments,
     :user_id]).freeze
  PROJECT_PERMITTED_FIELDS = (PROJECT_OTHER_FIELDS +
    ALL_CRITERIA_STATUS + ALL_CRITERIA_JUSTIFICATION).to_set.freeze
  PROJECT_PERMITTED_FIELDS_ARRAY = PROJECT_PERMITTED_FIELDS.to_a.freeze

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
    # validates column, allow_blank: true, length: { maximum: 25 }
    status = "#{criterion}_status".to_sym
    if Criteria[criterion.to_s]['na_allowed']
      validates status, inclusion: { in: STATUS_CHOICE_NA }
    else
      validates status, inclusion: { in: STATUS_CHOICE }
    end
    justification = "#{criterion}_justification".to_sym
    validates justification, length: { maximum: MAX_TEXT_LENGTH }
  end

  # TODO: Remove these Criteria queries from the project model

  # Is this criterion in the category MUST, SHOULD, or SUGGESTED?
  def self.criterion_category(criterion)
    (Criteria[criterion.to_s])[:category]
  end

  # Is na allowed?
  def self.na_allowed?(criterion)
    (Criteria[criterion.to_s])[:na_allowed]
  end

  # Is a URL required in the justification to be enough with met?
  def self.met_url_required?(criterion)
    (Criteria[criterion.to_s])[:met_url_required]
  end

  # Return badge level of the given project.
  # TODO: Should be normal method.
  def self.badge_level(project)
    if any_status_in_progress?(project)
      'in_progress'
    elsif all_status_passing?(project)
      'passing'
    else 'failing'
    end
  end

  def self.to_percentage(portion, total)
    if portion == total
      100
    elsif portion == 0
      0
    else
      ((portion * 100.0) / total).round
    end
  end

  # TODO: Should be normal method.
  def self.badge_percentage(project)
    met = ALL_ACTIVE_CRITERIA.count do |criterion|
      status = project["#{criterion}_status"]
      justification = project["#{criterion}_justification"]
      passing_criterion?(status, justification,
                         Criteria[criterion.to_s][:category],
                         Criteria[criterion.to_s][:met_url_required])
    end
    to_percentage met, ALL_ACTIVE_CRITERIA.length
  end

  def self.badge_level_id?(id)
    return false if id.nil?
    old_project = Project.find(id)
    if old_project
      badge_level(old_project)
    else
      'failing'
    end
  end

  # Do we have enough about this criterion to get a badge?
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def self.passing_criterion?(status, justification, category, met_needs_url)
    return true if category == 'FUTURE'
    case
    when status == 'N/A'
      true
    when status == 'Met'
      met_needs_url ? contains_url?(justification) : true
    when category == 'SHOULD' && status == 'Unmet' &&
      justification.length >= MIN_SHOULD_LENGTH
      true
    when category == 'SUGGESTED' && status != '?'
      true
    else false
    end
  end

  private

  def need_a_base_url
    return unless repo_url.blank? && project_homepage_url.blank?
    errors.add :base, 'Need at least a project or repository URL'
  end

  def self.any_status_in_progress?(project)
    ALL_ACTIVE_CRITERIA.any? do |criterion|
      status = project["#{criterion}_status"]
      status == '?' || status.blank?
    end
  end
  private_class_method :any_status_in_progress?

  def self.all_status_passing?(project)
    ALL_ACTIVE_CRITERIA.all? do |criterion|
      passing_criterion? project["#{criterion}_status"],
                         project["#{criterion}_justification"],
                         Criteria[criterion.to_s][:category],
                         Criteria[criterion.to_s][:met_url_required]
    end
  end
  private_class_method :all_status_passing?

  # TODO: define standard URL regex, then use everywhere.
  def self.contains_url?(text)
    return false if text.nil?
    text.match %r(https?://[^ ]{5,})
  end
  private_class_method :contains_url?

  # rubocop:enable Metrics/CyclomaticComplexity
end
