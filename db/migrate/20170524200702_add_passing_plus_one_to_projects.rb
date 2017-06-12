# frozen_string_literal: true

class AddPassingPlusOneToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :badge_percentage_1, :integer, default: 0

    add_column :projects, :dco_status, :string, default: '?'
    add_column :projects, :dco_justification, :text

    add_column :projects, :governance_status, :string, default: '?'
    add_column :projects, :governance_justification, :text

    add_column :projects, :code_of_conduct_status, :string, default: '?'
    add_column :projects, :code_of_conduct_justification, :text

    add_column :projects, :roles_responsibilities_status, :string, default: '?'
    add_column :projects, :roles_responsibilities_justification, :text

    add_column :projects, :access_continuity_status, :string, default: '?'
    add_column :projects, :access_continuity_justification, :text

    add_column :projects, :bus_factor_status, :string, default: '?'
    add_column :projects, :bus_factor_justification, :text

    add_column :projects, :documentation_roadmap_status, :string, default: '?'
    add_column :projects, :documentation_roadmap_justification, :text

    add_column :projects, :documentation_architecture_status, :string, default: '?'
    add_column :projects, :documentation_architecture_justification, :text

    add_column :projects, :documentation_security_status, :string, default: '?'
    add_column :projects, :documentation_security_justification, :text

    add_column :projects, :documentation_quick_start_status, :string, default: '?'
    add_column :projects, :documentation_quick_start_justification, :text

    add_column :projects, :documentation_current_status, :string, default: '?'
    add_column :projects, :documentation_current_justification, :text

    add_column :projects, :documentation_achievements_status, :string, default: '?'
    add_column :projects, :documentation_achievements_justification, :text

    add_column :projects, :accessibility_best_practices_status, :string, default: '?'
    add_column :projects, :accessibility_best_practices_justification, :text

    add_column :projects, :internationalization_status, :string, default: '?'
    add_column :projects, :internationalization_justification, :text

    add_column :projects, :sites_password_security_status, :string, default: '?'
    add_column :projects, :sites_password_security_justification, :text

    add_column :projects, :maintenance_or_update_status, :string, default: '?'
    add_column :projects, :maintenance_or_update_justification, :text

    add_column :projects, :vulnerability_report_credit_status, :string, default: '?'
    add_column :projects, :vulnerability_report_credit_justification, :text

    add_column :projects, :vulnerability_response_process_status, :string, default: '?'
    add_column :projects, :vulnerability_response_process_justification, :text

    add_column :projects, :coding_standards_status, :string, default: '?'
    add_column :projects, :coding_standards_justification, :text

    add_column :projects, :coding_standards_enforced_status, :string, default: '?'
    add_column :projects, :coding_standards_enforced_justification, :text

    add_column :projects, :build_standard_variables_status, :string, default: '?'
    add_column :projects, :build_standard_variables_justification, :text

    add_column :projects, :build_preserve_debug_status, :string, default: '?'
    add_column :projects, :build_preserve_debug_justification, :text

    add_column :projects, :build_non_recursive_status, :string, default: '?'
    add_column :projects, :build_non_recursive_justification, :text

    add_column :projects, :build_repeatable_status, :string, default: '?'
    add_column :projects, :build_repeatable_justification, :text

    add_column :projects, :installation_standard_variables_status, :string, default: '?'
    add_column :projects, :installation_standard_variables_justification, :text

    add_column :projects, :installation_development_quick_status, :string, default: '?'
    add_column :projects, :installation_development_quick_justification, :text

    add_column :projects, :external_dependencies_status, :string, default: '?'
    add_column :projects, :external_dependencies_justification, :text

    add_column :projects, :dependency_monitoring_status, :string, default: '?'
    add_column :projects, :dependency_monitoring_justification, :text

    add_column :projects, :updateable_reused_components_status, :string, default: '?'
    add_column :projects, :updateable_reused_components_justification, :text

    add_column :projects, :interfaces_current_status, :string, default: '?'
    add_column :projects, :interfaces_current_justification, :text

    add_column :projects, :automated_integration_testing_status, :string, default: '?'
    add_column :projects, :automated_integration_testing_justification, :text

    add_column :projects, :regression_tests_added50_status, :string, default: '?'
    add_column :projects, :regression_tests_added50_justification, :text

    add_column :projects, :test_statement_coverage80_status, :string, default: '?'
    add_column :projects, :test_statement_coverage80_justification, :text

    add_column :projects, :test_policy_mandated_status, :string, default: '?'
    add_column :projects, :test_policy_mandated_justification, :text

    add_column :projects, :implement_secure_design_status, :string, default: '?'
    add_column :projects, :implement_secure_design_justification, :text

    add_column :projects, :input_validation_status, :string, default: '?'
    add_column :projects, :input_validation_justification, :text

    add_column :projects, :crypto_algorithm_agility_status, :string, default: '?'
    add_column :projects, :crypto_algorithm_agility_justification, :text

    add_column :projects, :crypto_credential_agility_status, :string, default: '?'
    add_column :projects, :crypto_credential_agility_justification, :text

    add_column :projects, :signed_releases_status, :string, default: '?'
    add_column :projects, :signed_releases_justification, :text

    add_column :projects, :version_tags_signed_status, :string, default: '?'
    add_column :projects, :version_tags_signed_justification, :text
  end
end
