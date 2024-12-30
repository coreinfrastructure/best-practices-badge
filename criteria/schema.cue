//// Aliases ////

#URL: =~"^https?://[^\\s]+$"

#Link: {
  url: #URL
  description: string
}

#Justification: {
  description: string
  links?: [...#Link]
}

#UnmetJustification: {
  description: string
  links: [...#Link]
}

#Criterion: {
  result: "met" | "unmet" | "unknown"
  if result == "unmet" {
    unmet_justification: #UnmetJustification
  }
  if result == "met" {
    met_justification?: #MetJustification
  }
}

#NullableCriterion {
  result: "met" | "unmet" | "unknown" | "na"
  if result == "unmet" {
    justification: #UnmetJustification
  }
  if result == "met" {
    justification?: #Justification
  }
  if result == "na" {
    justification: #Justification
  }
}

//// Schema ////

project_identification:
  name: string
  description: string
  url: #URL
  primary_repo_url: #URL
  primary_languages: [...string]
  comment?: string
  cpe?: string
  disable_activity_reminder?: bool

passing?:
  Basics:
    description_good: #Criterion
    interact: #Criterion
    contribution: #Criterion
    contribution_requirements: #Criterion
    license_expression: string
    floss_license: #Criterion
    floss_license_osi: #Criterion
    license_location: #Criterion
    documentation_basics: #NullableCriterion
    documentation_interface: #NullableCriterion
    sites_https: #Criterion
    discussion: #Criterion
    english: #Criterion
    maintained: #Criterion
  'Change Control':
    repo_public: #Criterion
    repo_track: #Criterion
    repo_interim: #Criterion
    repo_distributed: #Criterion
    version_unique: #Criterion
    version_semver: #Criterion
    version_tags: #Criterion
    release_notes: #NullableCriterion
    release_notes_vulns: #NullableCriterion
  Reporting:
    report_process: #Criterion
    report_tracker: #Criterion
    report_responses: #Criterion
    enhancement_responses: #Criterion
    report_archive: #Criterion
    vulnerability_report_process: #Criterion
    vulnerability_report_private: #NullableCriterion
    vulnerability_report_response: #NullableCriterion
  Quality:
    build: #NullableCriterion
    build_common_tools: #NullableCriterion
    build_floss_tools: #NullableCriterion
    test: #Criterion
    test_invocation: #Criterion
    test_most: #Criterion
    test_continuous_integration: #Criterion
    test_policy: #Criterion
    tests_are_added: #Criterion
    tests_documented_added: #Criterion
    warnings: #NullableCriterion
    warnings_fixed: #NullableCriterion
    warnings_strict: #NullableCriterion
  Security:
    know_secure_design: #Criterion
    know_common_errors: #Criterion
    crypography_used: bool
    if crypography_used {
      crypto_published: #Criterion
      crypto_call: #Criterion
      crypto_floss: #Criterion
      crypto_keylength: #Criterion
      crypto_working: #Criterion
      crypto_weaknesses: #Criterion
      crypto_pfs: #Criterion
      crypto_password_storage: #Criterion
      crypto_random: #Criterion
    }
    delivery_mitm: #Criterion
    delivery_unsigned: #Criterion
    vulnerabilities_fixed_60_days: #Criterion
    vulnerabilities_critical_fixed: #Criterion
    no_leaked_credentials: #Criterion
  Analysis:
    static_analysis: #NullableCriterion
    static_analysis_common_vulnerabilities: #NullableCriterion
    static_analysis_fixed: #NullableCriterion
    static_analysis_often: #NullableCriterion
    dynamic_analysis: #Criterion
    dynamic_analysis_unsafe: #NullableCriterion
    dynamic_analysis_enable_assertions: #Criterion
    dynamic_analysis_fixed: #NullableCriterion
silver?:
  Basics:
    achieve_passing:
    contribution_requirements:
    dco:
    governance:
    code_of_conduct:
    roles_responsibilities:
    access_continuity:
    bus_factor:
    documentation_roadmap:
    documentation_architecture:
    documentation_security:
    documentation_quick_start:
    documentation_current:
    documentation_achievements:
    accessibility_best_practices:
    internationalization:
    sites_password_security:
  'Change Control':
    maintenance_or_update:
  Reporting:
    report_tracker:
    vulnerability_report_credit:
    vulnerability_response_process:
  Quality:
    coding_standards:
    coding_standards_enforced:
    build_standard_variables:
    build_preserve_debug:
    build_non_recursive:
    build_repeatable:
            that external parties be able to reproduce the results - merely
            build environment(s), which can be harder to do - so we have
    installation_common:
    installation_standard_variables:
    installation_development_quick:
    external_dependencies:
    dependency_monitoring:
    updateable_reused_components:
    interfaces_current:
    automated_integration_testing:
            person integrates at least daily - leading to multiple integrations
    regression_tests_added50:
    test_statement_coverage80:
    test_policy_mandated:
    tests_documented_added:
    warnings_strict:
  Security:
    implement_secure_design:
    crypto_weaknesses:
    crypto_algorithm_agility:
    crypto_credential_agility:
    crypto_used_network:
    crypto_tls12:
    crypto_certificate_verification:
    crypto_verification_private:
    signed_releases:
    version_tags_signed:
    input_validation:
    hardening:
    assurance_case:
  Analysis:
    static_analysis_common_vulnerabilities:
    dynamic_analysis_unsafe:
gold?:
  Basics:
    achieve_silver:
    bus_factor:
    contributors_unassociated:
    copyright_per_file:
    license_per_file:
  'Change Control':
    repo_distributed:
    small_tasks:
    require_2FA:
    secure_2FA:
  Quality:
    code_review_standards:
    two_person_review:
    build_reproducible:
    test_invocation:
    test_continuous_integration:
            integration focused on the first part - the frequent
            integration - and not on its testing.  However, over time the
    test_statement_coverage90:
    test_branch_coverage80:
  Security:
    crypto_used_network:
    crypto_tls12:
    hardened_site: # After delivery_mitm?
    security_review:
    hardening:
  Analysis:
    dynamic_analysis:
    dynamic_analysis_enable_assertions: