# rubocop:disable Metrics/ClassLength
class Project < ActiveRecord::Base
  STATUS_CHOICE = ['?', 'Met', 'Unmet']
  MIN_SHOULD_LENGTH = 5

  FIELD_CATEGORIES = {
    'description_sufficient' => 'MUST',
    'interact' => 'MUST',
    'contribution' => 'MUST',
    'contribution_criteria' => 'SHOULD',
    'license_location' => 'MUST',
    'oss_license' => 'MUST',
    'oss_license_osi' => 'SUGGESTED',
    'documentation_basics' => 'MUST',
    'documentation_interface' => 'MUST',
    'repo_url' => 'MUST',
    'repo_track' => 'MUST',
    'repo_interim' => 'MUST',
    'repo_distributed' => 'SUGGESTED',
    'version_unique' => 'MUST',
    'version_semver' => 'SUGGESTED',
    'version_tags' => 'SUGGESTED',
    'changelog' => 'MUST',
    'changelog_vulns' => 'MUST',
    'report_tracker' => 'SUGGESTED',
    'report_process' => 'MUST',
    'report_responses' => 'MUST',
    'enhancement_responses' => 'SHOULD',
    'report_archive' => 'MUST',
    'vulnerability_report_process' => 'MUST',
    'vulnerability_report_private' => 'MUST',
    'vulnerability_report_response' => 'MUST',
    'build' => 'MUST',
    'build_common_tools' => 'SUGGESTED',
    'build_oss_tools' => 'SHOULD',
    'test' => 'MUST',
    'test_invocation' => 'SHOULD',
    'test_most' => 'SUGGESTED',
    'test_policy' => 'MUST',
    'tests_are_added' => 'MUST',
    'tests_documented_added' => 'SUGGESTED',
    'warnings' => 'MUST',
    'warnings_fixed' => 'MUST',
    'warnings_strict' => 'SUGGESTED',
    'know_secure_design' => 'MUST',
    'know_common_errors' => 'MUST',
    'crypto_published' => 'MUST',
    'crypto_call' => 'MUST',
    'crypto_oss' => 'MUST',
    'crypto_keylength' => 'MUST',
    'crypto_working' => 'MUST',
    'crypto_pfs' => 'SHOULD',
    'crypto_password_storage' => 'MUST',
    'crypto_random' => 'MUST',
    'delivery_mitm' => 'MUST',
    'delivery_unsigned' => 'MUST',
    'vulnerabilities_fixed_60_days' => 'MUST',
    'vulnerabilities_critical_fixed' => 'SHOULD',
    'static_analysis' => 'MUST',
    'static_analysis_common_vulnerabilities' => 'SUGGESTED',
    'static_analysis_fixed' => 'MUST',
    'static_analysis_often' => 'SUGGESTED',
    'dynamic_analysis_unsafe' => 'MUST',
    'dynamic_analysis_enable_assertions' => 'SUGGESTED',
    'dynamic_analysis_fixed' => 'MUST' }.freeze

  # Peojects are associated with users
  belongs_to :user

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
  validates :project_url, url: true
  validate :need_a_url

  validates :user_id, presence: true

  validates :project_url_status, inclusion: { in: STATUS_CHOICE }
  validates :project_url_https_status, inclusion: { in: STATUS_CHOICE }
  validates :description_sufficient_status, inclusion: { in: STATUS_CHOICE }
  validates :interact_status, inclusion: { in: STATUS_CHOICE }
  validates :contribution_status, inclusion: { in: STATUS_CHOICE }
  validates :contribution_criteria_status, inclusion: { in: STATUS_CHOICE }
  validates :license_location_status, inclusion: { in: STATUS_CHOICE }
  validates :oss_license_status, inclusion: { in: STATUS_CHOICE }
  validates :oss_license_osi_status, inclusion: { in: STATUS_CHOICE }
  validates :documentation_basics_status, inclusion: { in: STATUS_CHOICE }
  validates :documentation_interface_status, inclusion: { in: STATUS_CHOICE }
  validates :repo_url_status, inclusion: { in: STATUS_CHOICE }
  validates :repo_track_status, inclusion: { in: STATUS_CHOICE }
  validates :repo_interim_status, inclusion: { in: STATUS_CHOICE }
  validates :repo_distributed_status, inclusion: { in: STATUS_CHOICE }
  validates :version_unique_status, inclusion: { in: STATUS_CHOICE }
  validates :version_semver_status, inclusion: { in: STATUS_CHOICE }
  validates :version_tags_status, inclusion: { in: STATUS_CHOICE }
  validates :changelog_status, inclusion: { in: STATUS_CHOICE }
  validates :changelog_vulns_status, inclusion: { in: STATUS_CHOICE }
  validates :report_url_status, inclusion: { in: STATUS_CHOICE }
  validates :report_tracker_status, inclusion: { in: STATUS_CHOICE }
  validates :report_process_status, inclusion: { in: STATUS_CHOICE }
  validates :report_responses_status, inclusion: { in: STATUS_CHOICE }
  validates :enhancement_responses_status, inclusion: { in: STATUS_CHOICE }
  validates :report_archive_status, inclusion: { in: STATUS_CHOICE }
  validates :vulnerability_report_process_status, inclusion:
                                                  { in: STATUS_CHOICE }
  validates :vulnerability_report_private_status, inclusion:
                                                  { in: STATUS_CHOICE }
  validates :vulnerability_report_response_status, inclusion:
                                                   { in: STATUS_CHOICE }
  validates :build_status, inclusion: { in: STATUS_CHOICE }
  validates :build_common_tools_status, inclusion: { in: STATUS_CHOICE }
  validates :build_oss_tools_status, inclusion: { in: STATUS_CHOICE }
  validates :test_status, inclusion: { in: STATUS_CHOICE }
  validates :test_invocation_status, inclusion: { in: STATUS_CHOICE }
  validates :test_most_status, inclusion: { in: STATUS_CHOICE }
  validates :test_policy_status, inclusion: { in: STATUS_CHOICE }
  validates :tests_are_added_status, inclusion: { in: STATUS_CHOICE }
  validates :tests_documented_added_status, inclusion: { in: STATUS_CHOICE }
  validates :warnings_status, inclusion: { in: STATUS_CHOICE }
  validates :warnings_fixed_status, inclusion: { in: STATUS_CHOICE }
  validates :warnings_strict_status, inclusion: { in: STATUS_CHOICE }
  validates :know_secure_design_status, inclusion: { in: STATUS_CHOICE }
  validates :know_common_errors_status, inclusion: { in: STATUS_CHOICE }
  validates :crypto_published_status, inclusion: { in: STATUS_CHOICE }
  validates :crypto_call_status, inclusion: { in: STATUS_CHOICE }
  validates :crypto_oss_status, inclusion: { in: STATUS_CHOICE }
  validates :crypto_keylength_status, inclusion: { in: STATUS_CHOICE }
  validates :crypto_working_status, inclusion: { in: STATUS_CHOICE }
  validates :crypto_pfs_status, inclusion: { in: STATUS_CHOICE }
  validates :crypto_password_storage_status, inclusion: { in: STATUS_CHOICE }
  validates :crypto_random_status, inclusion: { in: STATUS_CHOICE }
  validates :delivery_mitm_status, inclusion: { in: STATUS_CHOICE }
  validates :delivery_unsigned_status, inclusion: { in: STATUS_CHOICE }
  validates :vulnerabilities_fixed_60_days_status, inclusion:
                                                   { in: STATUS_CHOICE }
  validates :vulnerabilities_critical_fixed_status, inclusion:
                                                    { in: STATUS_CHOICE }
  validates :static_analysis_status, inclusion: { in: STATUS_CHOICE }
  validates :static_analysis_common_vulnerabilities_status,
            inclusion: { in: STATUS_CHOICE }
  validates :static_analysis_fixed_status, inclusion: { in: STATUS_CHOICE }
  validates :static_analysis_often_status, inclusion: { in: STATUS_CHOICE }
  validates :dynamic_analysis_status, inclusion: { in: STATUS_CHOICE }
  validates :dynamic_analysis_unsafe_status, inclusion: { in: STATUS_CHOICE }
  validates :dynamic_analysis_enable_assertions_status, inclusion:
                                                        { in: STATUS_CHOICE }
  validates :dynamic_analysis_fixed_status, inclusion: { in: STATUS_CHOICE }

  def self.field_category(field)
    FIELD_CATEGORIES[field]
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def self.valid_badge?(project)
    FIELD_CATEGORIES.all? do |key, value|
      criteria_status = (key + '_status')
      criteria_just = (key + '_justification')
      case value
      when 'MUST'
        project[criteria_status] == 'Met'
      when 'SHOULD'
        if project[criteria_status] == 'Met'
          true
        elsif project[criteria_status] == 'Unmet' &&
              (project[criteria_just].length >= MIN_SHOULD_LENGTH)
          true
        else
          false
        end
      when 'SUGGESTED'
        %w(Met Unmet).include? project[criteria_status]
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

  private

  def need_a_url
    return unless repo_url.blank? && project_url.blank?
    errors.add :base, 'Need at least a project or repository URL'
  end
end
