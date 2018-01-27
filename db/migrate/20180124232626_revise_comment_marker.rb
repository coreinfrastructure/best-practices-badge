# frozen_string_literal: true

class ReviseCommentMarker < ActiveRecord::Migration[5.1]
  # These are the fields for justification.  They're known at this
  # point, so we'll just list them.
  # Omitted (not actually database columns):
  # - require_2FA_justification
  # - secure_2FA_justification
  JUSTIFICATION_FIELDS = %w[
    homepage_url_justification
    sites_https_justification
    description_good_justification
    interact_justification
    contribution_justification
    contribution_requirements_justification
    license_location_justification
    floss_license_justification
    floss_license_osi_justification
    documentation_basics_justification
    documentation_interface_justification
    repo_public_justification
    repo_track_justification
    repo_interim_justification
    repo_distributed_justification
    version_unique_justification
    version_semver_justification
    version_tags_justification
    release_notes_justification
    release_notes_vulns_justification
    report_url_justification
    report_tracker_justification
    report_process_justification
    report_responses_justification
    enhancement_responses_justification
    report_archive_justification
    vulnerability_report_process_justification
    vulnerability_report_private_justification
    vulnerability_report_response_justification
    build_justification
    build_common_tools_justification
    build_floss_tools_justification
    test_justification
    test_invocation_justification
    test_most_justification
    test_policy_justification
    tests_are_added_justification
    tests_documented_added_justification
    warnings_justification
    warnings_fixed_justification
    warnings_strict_justification
    know_secure_design_justification
    know_common_errors_justification
    crypto_published_justification
    crypto_call_justification
    crypto_floss_justification
    crypto_keylength_justification
    crypto_working_justification
    crypto_pfs_justification
    crypto_password_storage_justification
    crypto_random_justification
    delivery_mitm_justification
    delivery_unsigned_justification
    vulnerabilities_fixed_60_days_justification
    vulnerabilities_critical_fixed_justification
    static_analysis_justification
    static_analysis_common_vulnerabilities_justification
    static_analysis_fixed_justification
    static_analysis_often_justification
    dynamic_analysis_justification
    dynamic_analysis_unsafe_justification
    dynamic_analysis_enable_assertions_justification
    dynamic_analysis_fixed_justification
    crypto_weaknesses_justification
    test_continuous_integration_justification
    discussion_justification
    no_leaked_credentials_justification
    english_justification
    hardening_justification
    crypto_used_network_justification
    crypto_tls12_justification
    crypto_certificate_verification_justification
    crypto_verification_private_justification
    hardened_site_justification
    installation_common_justification
    build_reproducible_justification
    dco_justification
    governance_justification
    code_of_conduct_justification
    roles_responsibilities_justification
    access_continuity_justification
    bus_factor_justification
    documentation_roadmap_justification
    documentation_architecture_justification
    documentation_security_justification
    documentation_quick_start_justification
    documentation_current_justification
    documentation_achievements_justification
    accessibility_best_practices_justification
    internationalization_justification
    sites_password_security_justification
    maintenance_or_update_justification
    vulnerability_report_credit_justification
    vulnerability_response_process_justification
    coding_standards_justification
    coding_standards_enforced_justification
    build_standard_variables_justification
    build_preserve_debug_justification
    build_non_recursive_justification
    build_repeatable_justification
    installation_standard_variables_justification
    installation_development_quick_justification
    external_dependencies_justification
    dependency_monitoring_justification
    updateable_reused_components_justification
    interfaces_current_justification
    automated_integration_testing_justification
    regression_tests_added50_justification
    test_statement_coverage80_justification
    test_policy_mandated_justification
    implement_secure_design_justification
    input_validation_justification
    crypto_algorithm_agility_justification
    crypto_credential_agility_justification
    signed_releases_justification
    version_tags_signed_justification
    contributors_unassociated_justification
    copyright_per_file_justification
    license_per_file_justification
    small_tasks_justification
    code_review_standards_justification
    two_person_review_justification
    test_statement_coverage90_justification
    test_branch_coverage80_justification
    security_review_justification
    assurance_case_justification
    achieve_passing_justification
    achieve_silver_justification
  ].freeze

  def sql_change_marker(field, old, new)
    # Return SQL to change comment marker from "old" to "new" for "field".
    # Presumes old and new are NOT special in SIMILAR TO.
    old_len = old.length + 1
    # Empty here document returns a string
    <<-SQL
      UPDATE projects
      SET #{field} =
          CONCAT('#{new} ', RIGHT(LTRIM(#{field}), -#{old_len}))
      WHERE #{field} similar to ' *#{old} %';
      SELECT id,#{field} FROM projects;
    SQL
  end

  def change
    JUSTIFICATION_FIELDS.each do |field|
      reversible do |dir|
        dir.up do
          execute sql_change_marker(field, '#', '//')
        end
        dir.down do
          execute sql_change_marker(field, '//', '#')
        end
      end
    end
  end
end
