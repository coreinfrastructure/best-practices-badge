# frozen_string_literal: true

# Modify many database fields to be "not null", that is, they
# MUST have a value.  This prevents some data problems.
# This uses:
# - change_column_null :table_name, :column_name, false
# where 'false' means 'is null allowed? false.'
# For unknown status values we use '?' and set it as the default.
# That way, the value displayed to the user in English
# is exactly the same as what we store.
class MakeManyNotNull < ActiveRecord::Migration[5.1]
  def change
    # users
    change_column_null :users, :provider, false
    # projects
    change_column_null :projects, :homepage_url_status, false
    change_column_null :projects, :sites_https_status, false
    change_column_null :projects, :description_good_status, false
    change_column_null :projects, :interact_status, false
    change_column_null :projects, :contribution_status, false
    change_column_null :projects, :contribution_requirements_status, false
    change_column_null :projects, :license_location_status, false
    change_column_null :projects, :floss_license_status, false
    change_column_null :projects, :floss_license_osi_status, false
    change_column_null :projects, :documentation_basics_status, false
    change_column_null :projects, :documentation_interface_status, false
    change_column_null :projects, :repo_public_status, false
    change_column_null :projects, :repo_track_status, false
    change_column_null :projects, :repo_interim_status, false
    change_column_null :projects, :repo_distributed_status, false
    change_column_null :projects, :version_unique_status, false
    change_column_null :projects, :version_semver_status, false
    change_column_null :projects, :version_tags_status, false
    change_column_null :projects, :release_notes_status, false
    change_column_null :projects, :release_notes_vulns_status, false
    change_column_null :projects, :report_url_status, false
    change_column_null :projects, :report_tracker_status, false
    change_column_null :projects, :report_process_status, false
    change_column_null :projects, :report_responses_status, false
    change_column_null :projects, :enhancement_responses_status, false
    change_column_null :projects, :report_archive_status, false
    change_column_null :projects, :vulnerability_report_process_status, false
    change_column_null :projects, :vulnerability_report_private_status, false
    change_column_null :projects, :vulnerability_report_response_status, false
    change_column_null :projects, :build_status, false
    change_column_null :projects, :build_common_tools_status, false
    change_column_null :projects, :build_floss_tools_status, false
    change_column_null :projects, :test_status, false
    change_column_null :projects, :test_invocation_status, false
    change_column_null :projects, :test_most_status, false
    change_column_null :projects, :test_policy_status, false
    change_column_null :projects, :tests_are_added_status, false
    change_column_null :projects, :tests_documented_added_status, false
    change_column_null :projects, :warnings_status, false
    change_column_null :projects, :warnings_fixed_status, false
    change_column_null :projects, :warnings_strict_status, false
    change_column_null :projects, :know_secure_design_status, false
    change_column_null :projects, :know_common_errors_status, false
    change_column_null :projects, :crypto_published_status, false
    change_column_null :projects, :crypto_call_status, false
    change_column_null :projects, :crypto_floss_status, false
    change_column_null :projects, :crypto_keylength_status, false
    change_column_null :projects, :crypto_working_status, false
    change_column_null :projects, :crypto_pfs_status, false
    change_column_null :projects, :crypto_password_storage_status, false
    change_column_null :projects, :crypto_random_status, false
    change_column_null :projects, :delivery_mitm_status, false
    change_column_null :projects, :delivery_unsigned_status, false
    change_column_null :projects, :vulnerabilities_fixed_60_days_status, false
    change_column_null :projects, :vulnerabilities_critical_fixed_status, false
    change_column_null :projects, :static_analysis_status, false
    change_column_null :projects,
                       :static_analysis_common_vulnerabilities_status, false
    change_column_null :projects, :static_analysis_fixed_status, false
    change_column_null :projects, :static_analysis_often_status, false
    change_column_null :projects, :dynamic_analysis_status, false
    change_column_null :projects, :dynamic_analysis_unsafe_status, false
    change_column_null :projects,
                       :dynamic_analysis_enable_assertions_status, false
    change_column_null :projects, :dynamic_analysis_fixed_status, false
    change_column_null :projects, :crypto_weaknesses_status, false
    change_column_null :projects, :test_continuous_integration_status, false
    change_column_null :projects, :discussion_status, false
    change_column_null :projects, :no_leaked_credentials_status, false
    change_column_null :projects, :english_status, false
    change_column_null :projects, :hardening_status, false
    change_column_null :projects, :crypto_used_network_status, false
    change_column_null :projects, :crypto_tls12_status, false
    change_column_null :projects, :crypto_certificate_verification_status, false
    change_column_null :projects, :crypto_verification_private_status, false
    change_column_null :projects, :hardened_site_status, false
    change_column_null :projects, :installation_common_status, false
    change_column_null :projects, :build_reproducible_status, false
    change_column_null :projects, :dco_status, false
    change_column_null :projects, :governance_status, false
    change_column_null :projects, :code_of_conduct_status, false
    change_column_null :projects, :roles_responsibilities_status, false
    change_column_null :projects, :access_continuity_status, false
    change_column_null :projects, :bus_factor_status, false
    change_column_null :projects, :documentation_roadmap_status, false
    change_column_null :projects, :documentation_architecture_status, false
    change_column_null :projects, :documentation_security_status, false
    change_column_null :projects, :documentation_quick_start_status, false
    change_column_null :projects, :documentation_current_status, false
    change_column_null :projects, :documentation_achievements_status, false
    change_column_null :projects, :accessibility_best_practices_status, false
    change_column_null :projects, :internationalization_status, false
    change_column_null :projects, :sites_password_security_status, false
    change_column_null :projects, :maintenance_or_update_status, false
    change_column_null :projects, :vulnerability_report_credit_status, false
    change_column_null :projects, :vulnerability_response_process_status, false
    change_column_null :projects, :coding_standards_status, false
    change_column_null :projects, :coding_standards_enforced_status, false
    change_column_null :projects, :build_standard_variables_status, false
    change_column_null :projects, :build_preserve_debug_status, false
    change_column_null :projects, :build_non_recursive_status, false
    change_column_null :projects, :build_repeatable_status, false
    change_column_null :projects, :installation_standard_variables_status, false
    change_column_null :projects, :installation_development_quick_status, false
    change_column_null :projects, :external_dependencies_status, false
    change_column_null :projects, :dependency_monitoring_status, false
    change_column_null :projects, :updateable_reused_components_status, false
    change_column_null :projects, :interfaces_current_status, false
    change_column_null :projects, :automated_integration_testing_status, false
    change_column_null :projects, :regression_tests_added50_status, false
    change_column_null :projects, :test_statement_coverage80_status, false
    change_column_null :projects, :test_policy_mandated_status, false
    change_column_null :projects, :implement_secure_design_status, false
    change_column_null :projects, :input_validation_status, false
    change_column_null :projects, :crypto_algorithm_agility_status, false
    change_column_null :projects, :crypto_credential_agility_status, false
    change_column_null :projects, :signed_releases_status, false
    change_column_null :projects, :version_tags_signed_status, false
    change_column_null :projects, :contributors_unassociated_status, false
    change_column_null :projects, :copyright_per_file_status, false
    change_column_null :projects, :license_per_file_status, false
    change_column_null :projects, :small_tasks_status, false
    change_column_null :projects, :require_2FA_status, false
    change_column_null :projects, :secure_2FA_status, false
    change_column_null :projects, :code_review_standards_status, false
    change_column_null :projects, :two_person_review_status, false
    change_column_null :projects, :test_statement_coverage90_status, false
    change_column_null :projects, :test_branch_coverage80_status, false
    change_column_null :projects, :security_review_status, false
    change_column_null :projects, :assurance_case_status, false
  end
end
