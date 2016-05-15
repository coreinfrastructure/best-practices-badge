# frozen_string_literal: true
class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.references :user, index: true, foreign_key: true
      # OSS PROJECT BASICS
      # Identification
      t.string :name
      t.text :description
      t.string :project_url
      t.string :repo_url
      t.string :license
      # Project Website (auto-populated, currently not in the form)
      t.string :project_url_status
      t.text :project_url_justification
      t.string :project_url_https_status
      t.text :project_url_https_justification
      # Basic Project Website Content
      t.string :description_sufficient_status
      t.text :description_sufficient_justification
      t.string :interact_status
      t.text :interact_justification
      t.string :contribution_status
      t.text :contribution_justification
      t.string :contribution_criteria_status
      t.text :contribution_criteria_justification
      # OSS License
      t.string :license_location_status
      t.text :license_location_justification
      t.string :oss_license_status
      t.text :oss_license_justification
      t.string :oss_license_osi_status
      t.text :oss_license_osi_justification
      # Documentation
      t.string :documentation_basics_status
      t.text :documentation_basics_justification
      t.string :documentation_interface_status
      t.text :documentation_interface_justification
      # CHANGE CONTROL
      # Public version-controlled source repository
      t.string :repo_url_status
      t.text :repo_url_justification
      t.string :repo_track_status
      t.text :repo_track_justification
      t.string :repo_interim_status
      t.text :repo_interim_justification
      t.string :repo_distributed_status
      t.text :repo_distributed_justification
      # Version numbering
      t.string :version_unique_status
      t.text :version_unique_justification
      t.string :version_semver_status
      t.text :version_semver_justification
      t.string :version_tags_status
      t.text :version_tags_justification
      # ChangeLog
      t.string :changelog_status
      t.text :changelog_justification
      t.string :changelog_vulns_status
      t.text :changelog_vulns_justification
      # REPORTING
      # Bug-reporting process
      t.string :report_url_status
      t.text :report_url_justification
      t.string :report_tracker_status
      t.text :report_tracker_justification
      t.string :report_process_status
      t.text :report_process_justification
      t.string :report_responses_status
      t.text :report_responses_justification
      t.string :enhancement_responses_status
      t.text :enhancement_responses_justification
      t.string :report_archive_status
      t.text :report_archive_justification
      # Vulnerability report process
      t.string :vulnerability_report_process_status
      t.text :vulnerability_report_process_justification
      t.string :vulnerability_report_private_status
      t.text :vulnerability_report_private_justification
      t.string :vulnerability_report_response_status
      t.text :vulnerability_report_response_justification
      # QUALITY
      # Working build system
      t.string :build_status
      t.text :build_justification
      t.string :build_common_tools_status
      t.text :build_common_tools_justification
      t.string :build_oss_tools_status
      t.text :build_oss_tools_justification
      # Automated test suite
      t.string :test_status
      t.text :test_justification
      t.string :test_invocation_status
      t.text :test_invocation_justification
      t.string :test_most_status
      t.text :test_most_justification
      # New functionality testing
      t.string :test_policy_status
      t.text :test_policy_justification
      t.string :tests_are_added_status
      t.text :tests_are_added_justification
      t.string :tests_documented_added_status
      t.text :tests_documented_added_justification
      # Warning flags
      t.string :warnings_status
      t.text :warnings_justification
      t.string :warnings_fixed_status
      t.text :warnings_fixed_justification
      t.string :warnings_strict_status
      t.text :warnings_strict_justification
      # SECURITY
      # Secure development knowledge
      t.string :know_secure_design_status
      t.text :know_secure_design_justification
      t.string :know_common_errors_status
      t.text :know_common_errors_justification
      # Use basic good cryptographic practices
      t.string :crypto_published_status
      t.text :crypto_published_justification
      t.string :crypto_call_status
      t.text :crypto_call_justification
      t.string :crypto_oss_status
      t.text :crypto_oss_justification
      t.string :crypto_keylength_status
      t.text :crypto_keylength_justification
      t.string :crypto_working_status
      t.text :crypto_working_justification
      t.string :crypto_pfs_status
      t.text :crypto_pfs_justification
      t.string :crypto_password_storage_status
      t.text :crypto_password_storage_justification
      t.string :crypto_random_status
      t.text :crypto_random_justification
      # Secured delivery against man-in-the-middle (MITM) attacks
      t.string :delivery_mitm_status
      t.text :delivery_mitm_justification
      t.string :delivery_unsigned_status
      t.text :delivery_unsigned_justification
      # Publicly-known Vulnerabilities fixed
      t.string :vulnerabilities_fixed_60_days_status
      t.text :vulnerabilities_fixed_60_days_justification
      t.string :vulnerabilities_critical_fixed_status
      t.text :vulnerabilities_critical_fixed_justification
      # SECURITY ANALYSIS
      # Static Code Analysis
      t.string :static_analysis_status
      t.text :static_analysis_justification
      t.string :static_analysis_common_vulnerabilities_status
      t.text :static_analysis_common_vulnerabilities_justification
      t.string :static_analysis_fixed_status
      t.text :static_analysis_fixed_justification
      t.string :static_analysis_often_status
      t.text :static_analysis_often_justification
      # Dynamic Analysis
      t.string :dynamic_analysis_status
      t.text :dynamic_analysis_justification
      t.string :dynamic_analysis_unsafe_status
      t.text :dynamic_analysis_unsafe_justification
      t.string :dynamic_analysis_enable_assertions_status
      t.text :dynamic_analysis_enable_assertions_justification
      t.string :dynamic_analysis_fixed_status
      t.text :dynamic_analysis_fixed_justification

      # COMMENTS ABOUT THE PROJECT
      t.text :general_comments

      t.timestamps null: false
    end
    add_index :projects, %i(user_id created_at)
  end
end
