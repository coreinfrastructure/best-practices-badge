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
  validates :project_url, format: { with:
    /\A(|https?:\/\/[A-Za-z0-9][-A-Za-z0-9_.\/]*(\/[-A-Za-z0-9_.\/\+,#]*)?)\z/,
                                    message: 'URL must begin with http: or https: and use a limited charset' }
  validates :repo_url, format: { with:
    /\A(|https?:\/\/[A-Za-z0-9][-A-Za-z0-9_.\/]*(\/[-A-Za-z0-9_.\/\+,#]*)?)\z/,
                                 message: 'URL must begin with http: or https: and use a limited charset' }

  STATUS_CHOICE = ['?', 'Met', 'Unmet']
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
end
