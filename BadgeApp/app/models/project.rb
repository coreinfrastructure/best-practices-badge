class Project < ActiveRecord::Base
  # Record information about a project.
  # We'll also record previous versions of information:
  has_paper_trail

  # Currently no validation rules for:
  #  name, description, license, *_justification
  # We'll rely on Rails' HTML escaping system to counter XSS.
  # The URL validation rules are somewhat overly strict, but should serve;
  # the idea is to prevent attackers from inserting redirecting URLs
  # that can sometimes be used to attack (e.g., "?...", or ones with <).
  validates :project_url, format: {
    with: /\A(|https?:\/\/[A-Za-z0-9][-A-Za-z0-9_.\/]*(\/[-A-Za-z0-9_.\/\+,#]*)?)\z/,
    message: 'URL must begin with http: or https: and use a limited charset' }
  validates :repo_url, format: {
    with: /\A(|https?:\/\/[A-Za-z0-9][-A-Za-z0-9_.\/]*(\/[-A-Za-z0-9_.\/\+,#]*)?)\z/,
    message: 'URL must begin with http: or https: and use a limited charset' }

  STATUS_CHOICE = ['?', 'Met', 'Unmet']
  validates_inclusion_of :project_url_status, in: STATUS_CHOICE
  validates_inclusion_of :project_url_https_status, in: STATUS_CHOICE
  validates_inclusion_of :description_sufficient_status, in: STATUS_CHOICE
  validates_inclusion_of :interact_status, in: STATUS_CHOICE
  validates_inclusion_of :contribution_status, in: STATUS_CHOICE
  validates_inclusion_of :contribution_criteria_status, in: STATUS_CHOICE
  validates_inclusion_of :license_location_status, in: STATUS_CHOICE
  validates_inclusion_of :oss_license_status, in: STATUS_CHOICE
  validates_inclusion_of :oss_license_osi_status, in: STATUS_CHOICE
  validates_inclusion_of :documentation_basics_status, in: STATUS_CHOICE
  validates_inclusion_of :documentation_interface_status, in: STATUS_CHOICE
  validates_inclusion_of :repo_url_status, in: STATUS_CHOICE
  validates_inclusion_of :repo_track_status, in: STATUS_CHOICE
  validates_inclusion_of :repo_interim_status, in: STATUS_CHOICE
  validates_inclusion_of :repo_distributed_status, in: STATUS_CHOICE
  validates_inclusion_of :version_unique_status, in: STATUS_CHOICE
  validates_inclusion_of :version_semver_status, in: STATUS_CHOICE
  validates_inclusion_of :version_tags_status, in: STATUS_CHOICE
  validates_inclusion_of :changelog_status, in: STATUS_CHOICE
  validates_inclusion_of :changelog_vulns_status, in: STATUS_CHOICE
  validates_inclusion_of :report_url_status, in: STATUS_CHOICE
  validates_inclusion_of :report_tracker_status, in: STATUS_CHOICE
  validates_inclusion_of :report_process_status, in: STATUS_CHOICE
  validates_inclusion_of :report_responses_status, in: STATUS_CHOICE
  validates_inclusion_of :enhancement_responses_status, in: STATUS_CHOICE
  validates_inclusion_of :report_archive_status, in: STATUS_CHOICE
  validates_inclusion_of :vulnerability_report_process_status, in: STATUS_CHOICE
  validates_inclusion_of :vulnerability_report_private_status, in: STATUS_CHOICE
  validates_inclusion_of :vulnerability_report_response_status, in: STATUS_CHOICE
  validates_inclusion_of :build_status, in: STATUS_CHOICE
  validates_inclusion_of :build_common_tools_status, in: STATUS_CHOICE
  validates_inclusion_of :build_oss_tools_status, in: STATUS_CHOICE
  validates_inclusion_of :test_status, in: STATUS_CHOICE
  validates_inclusion_of :test_invocation_status, in: STATUS_CHOICE
  validates_inclusion_of :test_most_status, in: STATUS_CHOICE
  validates_inclusion_of :test_policy_status, in: STATUS_CHOICE
  validates_inclusion_of :tests_are_added_status, in: STATUS_CHOICE
  validates_inclusion_of :tests_documented_added_status, in: STATUS_CHOICE
  validates_inclusion_of :warnings_status, in: STATUS_CHOICE
  validates_inclusion_of :warnings_fixed_status, in: STATUS_CHOICE
  validates_inclusion_of :warnings_strict_status, in: STATUS_CHOICE
  validates_inclusion_of :know_secure_design_status, in: STATUS_CHOICE
  validates_inclusion_of :know_common_errors_status, in: STATUS_CHOICE
  validates_inclusion_of :crypto_published_status, in: STATUS_CHOICE
  validates_inclusion_of :crypto_call_status, in: STATUS_CHOICE
  validates_inclusion_of :crypto_oss_status, in: STATUS_CHOICE
  validates_inclusion_of :crypto_keylength_status, in: STATUS_CHOICE
  validates_inclusion_of :crypto_working_status, in: STATUS_CHOICE
  validates_inclusion_of :crypto_pfs_status, in: STATUS_CHOICE
  validates_inclusion_of :crypto_password_storage_status, in: STATUS_CHOICE
  validates_inclusion_of :crypto_random_status, in: STATUS_CHOICE
  validates_inclusion_of :delivery_mitm_status, in: STATUS_CHOICE
  validates_inclusion_of :delivery_unsigned_status, in: STATUS_CHOICE
  validates_inclusion_of :vulnerabilities_fixed_60_days_status, in: STATUS_CHOICE
  validates_inclusion_of :vulnerabilities_critical_fixed_status, in: STATUS_CHOICE
  validates_inclusion_of :static_analysis_status, in: STATUS_CHOICE
  validates_inclusion_of :static_analysis_common_vulnerabilities_status, in: STATUS_CHOICE
  validates_inclusion_of :static_analysis_fixed_status, in: STATUS_CHOICE
  validates_inclusion_of :static_analysis_often_status, in: STATUS_CHOICE
  validates_inclusion_of :dynamic_analysis_status, in: STATUS_CHOICE
  validates_inclusion_of :dynamic_analysis_unsafe_status, in: STATUS_CHOICE
  validates_inclusion_of :dynamic_analysis_enable_assertions_status, in: STATUS_CHOICE
  validates_inclusion_of :dynamic_analysis_fixed_status, in: STATUS_CHOICE
end
