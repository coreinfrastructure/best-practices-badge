# rubocop:disable Metrics/ClassLength
class Project < ActiveRecord::Base
  STATUS_CHOICE = %w(? Met Unmet).freeze
  STATUS_CHOICE_NA = (STATUS_CHOICE + %w(N/A)).freeze
  MIN_SHOULD_LENGTH = 5
  MAX_TEXT_LENGTH = 8192 # Arbitrary maximum to reduce abuse
  MAX_SHORT_STRING_LENGTH = 254 # Arbitrary maximum to reduce abuse

  # Map each criterion to ['MUST|SHOULD|SUGGESTED',
  #   na_allowed?, met_requires_url?]
  CRITERIA_INFO = {
    # Basic Project Website Content
    description_sufficient: ['MUST', false, false],
    interact: ['MUST', false, false],
    contribution: ['MUST', false, true],
    contribution_criteria: ['SHOULD', false, true],
    # OSS License
    license_location: ['MUST', false, true],
    oss_license: ['MUST', false, false],
    oss_license_osi: ['SUGGESTED', false, false],
    # Documentation
    documentation_basics: ['MUST', false, false],
    documentation_interface: ['MUST', false, false],
    # CHANGE CONTROL
    # Public version-controlled source repository
    repo_url: ['MUST', false, false],
    repo_track: ['MUST', false, false],
    repo_interim: ['MUST', false, false],
    repo_distributed: ['SUGGESTED', false, false],
    # Unique version numbering
    version_unique: ['MUST', false, false],
    version_semver: ['SUGGESTED', false, false],
    version_tags: ['SUGGESTED', false, false],
    # ChangeLog
    changelog: ['MUST', false, true],
    changelog_vulns: ['MUST', false, false],
    # REPORTING
    # Bug-reporting process
    report_tracker: ['SUGGESTED', false, false],
    report_process: ['MUST', false, true],
    report_responses: ['MUST', false, false],
    enhancement_responses: ['SHOULD', false, false],
    report_archive: ['MUST', false, true],
    # Vulnerability report process
    vulnerability_report_process: ['MUST', false, true],
    vulnerability_report_private: ['MUST', true, true],
    vulnerability_report_response: ['MUST', false, false],
    # QUALITY
    # Working build system
    build: ['MUST', true, false],
    build_common_tools: ['SUGGESTED', true, false],
    build_oss_tools: ['SHOULD', true, false],
    # Automated test suite
    test: ['MUST', false, false],
    test_invocation: ['SHOULD', false, false],
    test_most: ['SUGGESTED', false, false],
    test_continuous_integration: ['SUGGESTED', false, false],
    # New functionality testing
    test_policy: ['MUST', false, false],
    tests_are_added: ['MUST', false, false],
    tests_documented_added: ['SUGGESTED', false, false],
    # Warning flags
    warnings: ['MUST', true, false],
    warnings_fixed: ['MUST', true, false],
    warnings_strict: ['SUGGESTED', true, false],
    # SECURITY
    # Secure development knowledge
    know_secure_design: ['MUST', false, false],
    know_common_errors: ['MUST', false, false],
    # Use basic good cryptographic practices
    crypto_published: ['MUST', true, false],
    crypto_call: ['MUST', true, false],
    crypto_oss: ['MUST', true, false],
    crypto_keylength: ['MUST', true, false],
    crypto_working: ['MUST', true, false],
    crypto_weaknesses: ['SHOULD', true, false],
    crypto_alternatives: ['SHOULD', true, false],
    crypto_pfs: ['SHOULD', true, false],
    crypto_password_storage: ['MUST', true, false],
    crypto_random: ['MUST', true, false],
    # Secured delivery against man-in-the-middle (MITM) attacks
    delivery_mitm: ['MUST', false, false],
    delivery_unsigned: ['MUST', false, false],
    # Publicly-known Vulnerabilities fixed
    vulnerabilities_fixed_60_days: ['MUST', false, false],
    vulnerabilities_critical_fixed: ['SHOULD', false, false],
    # ANALYSIS
    # Static code analysis
    static_analysis: ['MUST', true, false],
    static_analysis_common_vulnerabilities: ['SUGGESTED', true, false],
    static_analysis_fixed: ['MUST', true, false],
    static_analysis_often: ['SUGGESTED', true, false],
    # Dynamic code analysis
    dynamic_analysis: ['SUGGESTED', false, false],
    dynamic_analysis_unsafe: ['SUGGESTED', true, false],
    dynamic_analysis_enable_assertions: ['SUGGESTED', false, false],
    dynamic_analysis_fixed: ['MUST', false, false] }.freeze

  # Peojects are associated with users
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

  validates :repo_url, url: true, length: { maximum: MAX_SHORT_STRING_LENGTH }
  validates :project_homepage_url,
            url: true,
            length: { maximum: MAX_SHORT_STRING_LENGTH }
  validate :need_a_base_url

  validates :user_id, presence: true

  CRITERIA_INFO.each do |criterion, info|
    # validates column, allow_blank: true, length: { maximum: 25 }
    status = "#{criterion}_status".to_sym
    validates status, inclusion: (
      info[1] ? { in: STATUS_CHOICE_NA } : { in: STATUS_CHOICE })
    justification = "#{criterion}_justification".to_sym
    validates justification, length: { maximum: MAX_TEXT_LENGTH }
  end

  # Is this criterion in the category MUST, SHOULD, or SUGGESTED?
  def self.criterion_category(criterion)
    (CRITERIA_INFO[criterion.to_sym])[0]
  end

  # Is na allowed?
  def self.na_allowed?(criterion)
    (CRITERIA_INFO[criterion.to_sym])[1]
  end

  # Is a URL required in the justification to be enough with met?
  def self.met_url_required?(criterion)
    (CRITERIA_INFO[criterion.to_sym])[2]
  end

  def self.badge_achieved?(project)
    CRITERIA_INFO.all? do |criterion, value|
      status = project["#{criterion}_status"]
      justification = project["#{criterion}_justification"]
      enough_criterion? status, justification, value[0], value[2]
    end
  end

  private

  def need_a_base_url
    return unless repo_url.blank? && project_homepage_url.blank?
    errors.add :base, 'Need at least a project or repository URL'
  end

  # TODO: define standard URL regex, then use everywhere.
  def self.contains_url?(text)
    return false if text.nil?
    text.match %r(https?://[^ ]{5,})
  end

  # Do we have enough about this criterion to get a badge?
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def self.enough_criterion?(status, justification, category, met_needs_url)
    case
    when status == 'N/A'
      true
    when status == 'Met'
      met_needs_url ? self.contains_url?(justification) : true
    when category == 'SHOULD' && status == 'Unmet' &&
      justification.length >= MIN_SHOULD_LENGTH
      true
    when category == 'SUGGESTED' && status != '?'
      true
    else false
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
