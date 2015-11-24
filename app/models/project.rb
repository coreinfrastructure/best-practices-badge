# rubocop:disable Metrics/ClassLength
class Project < ActiveRecord::Base
  STATUS_CHOICE = %w(? Met Unmet).freeze
  STATUS_CHOICE_NA = (STATUS_CHOICE + %w(N/A)).freeze
  MIN_SHOULD_LENGTH = 5

  # Map each criterion to ['MUST|SHOULD|SUGGESTED', na_allowed?]
  CRITERIA_INFO = {
    # Basic Project Website Content
    description_sufficient: ['MUST', false],
    interact: ['MUST', false],
    contribution: ['MUST', false],
    contribution_criteria: ['SHOULD', false],
    # OSS License
    license_location: ['MUST', false],
    oss_license: ['MUST', false],
    oss_license_osi: ['SUGGESTED', false],
    # Documentation
    documentation_basics: ['MUST', false],
    documentation_interface: ['MUST', false],
    # CHANGE CONTROL
    # Public version-controlled source repository
    repo_url: ['MUST', false],
    repo_track: ['MUST', false],
    repo_interim: ['MUST', false],
    repo_distributed: ['SUGGESTED', false],
    # Unique version numbering
    version_unique: ['MUST', false],
    version_semver: ['SUGGESTED', false],
    version_tags: ['SUGGESTED', false],
    # ChangeLog
    changelog: ['MUST', false],
    changelog_vulns: ['MUST', false],
    # REPORTING
    # Bug-reporting process
    report_tracker: ['SUGGESTED', false],
    report_process: ['MUST', false],
    report_responses: ['MUST', false],
    enhancement_responses: ['SHOULD', false],
    report_archive: ['MUST', false],
    # Vulnerability report process
    vulnerability_report_process: ['MUST', false],
    vulnerability_report_private: ['MUST', false],
    vulnerability_report_response: ['MUST', false],
    # QUALITY
    # Working build system
    build: ['MUST', false],
    build_common_tools: ['SUGGESTED', false],
    build_oss_tools: ['SHOULD', false],
    # Automated test suite
    test: ['MUST', false],
    test_invocation: ['SHOULD', false],
    test_most: ['SUGGESTED', false],
    test_continuous_integration: ['SUGGESTED', false],
    # New functionality testing
    test_policy: ['MUST', false],
    tests_are_added: ['MUST', false],
    tests_documented_added: ['SUGGESTED', false],
    # Warning flags
    warnings: ['MUST', true],
    warnings_fixed: ['MUST', true],
    warnings_strict: ['SUGGESTED', true],
    # SECURITY
    # Secure development knowledge
    know_secure_design: ['MUST', false],
    know_common_errors: ['MUST', false],
    # Use basic good cryptographic practices
    crypto_published: ['MUST', true],
    crypto_call: ['MUST', true],
    crypto_oss: ['MUST', true],
    crypto_keylength: ['MUST', true],
    crypto_working: ['MUST', true],
    crypto_weaknesses: ['SHOULD', true],
    crypto_alternatives: ['SHOULD', true],
    crypto_pfs: ['SHOULD', true],
    crypto_password_storage: ['MUST', true],
    crypto_random: ['MUST', true],
    # Secured delivery against man-in-the-middle (MITM) attacks
    delivery_mitm: ['MUST', false],
    delivery_unsigned: ['MUST', false],
    # Publicly-known Vulnerabilities fixed
    vulnerabilities_fixed_60_days: ['MUST', false],
    vulnerabilities_critical_fixed: ['SHOULD', false],
    # ANALYSIS
    # Static code analysis
    static_analysis: ['MUST', true],
    static_analysis_common_vulnerabilities: ['SUGGESTED', false],
    static_analysis_fixed: ['MUST', false],
    static_analysis_often: ['SUGGESTED', false],
    # Dynamic code analysis
    dynamic_analysis: ['SUGGESTED', false],
    dynamic_analysis_unsafe: ['SUGGESTED', true],
    dynamic_analysis_enable_assertions: ['SUGGESTED', false],
    dynamic_analysis_fixed: ['MUST', false] }.freeze

  # Peojects are associated with users
  belongs_to :user
  delegate :name, to: :user, prefix: true

  default_scope { order(:created_at) }

  # Record information about a project.
  # We'll also record previous versions of information:
  has_paper_trail

  # Currently no validation rules for:
  #  name, description, license, *_justification
  # We'll rely on Rails' HTML escaping system to counter XSS.

  # We'll do automated analysis on these URLs, which means we will *download*
  # from URLs provided by untrusted users.  Thus we'll add additional
  # URL restrictions to counter tricks like http://ACCOUNT:PASSWORD@host...
  # and http://something/?arbitrary_parameters

  validates :repo_url, url: true
  validates :project_homepage_url, url: true
  validate :need_a_url

  validates :user_id, presence: true

  CRITERIA_INFO.each do |criterion, info|
    # validates column, allow_blank: true, length: { maximum: 25 }
    status = "#{criterion}_status".to_sym
    validates status, inclusion: (
      info[1] ? { in: STATUS_CHOICE_NA } : { in: STATUS_CHOICE })
  end

  def self.criterion_category(field)
    (CRITERIA_INFO[field.to_sym])[0]
  end

  def self.valid_badge?(project)
    CRITERIA_INFO.all? do |criterion, value|
      status = project["#{criterion}_status"]
      justification = project["#{criterion}_justification"]
      valid_category? status, justification, value[0]
    end
  end

  private

  def need_a_url
    return unless repo_url.blank? && project_homepage_url.blank?
    errors.add :base, 'Need at least a project or repository URL'
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.valid_category?(status, justification, value)
    case
    when status.in?(%w(Met N/A))
      true
    when value == 'SHOULD' && status == 'Unmet' &&
      justification.length >= MIN_SHOULD_LENGTH
      true
    when value == 'SUGGESTED' && status != '?'
      true
    else false
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
