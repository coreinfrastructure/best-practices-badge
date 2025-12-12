# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_05_215107) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "additional_rights", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "project_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["project_id"], name: "index_additional_rights_on_project_id"
    t.index ["user_id", "project_id"], name: "index_additional_rights_on_user_id_and_project_id", unique: true
    t.index ["user_id"], name: "index_additional_rights_on_user_id"
  end

  create_table "bad_passwords", id: false, force: :cascade do |t|
    t.string "forbidden_hash"
    t.index ["forbidden_hash"], name: "index_bad_passwords_on_forbidden_hash"
  end

  create_table "pg_search_documents", id: :serial, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.integer "searchable_id"
    t.string "searchable_type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "project_stats", id: :serial, force: :cascade do |t|
    t.integer "active_edited_in_progress"
    t.integer "active_edited_projects"
    t.integer "active_in_progress"
    t.integer "active_projects"
    t.integer "additional_rights_entries"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_since_yesterday", null: false
    t.integer "github_users"
    t.integer "local_users"
    t.integer "percent_1_ge_100"
    t.integer "percent_1_ge_25"
    t.integer "percent_1_ge_50"
    t.integer "percent_1_ge_75"
    t.integer "percent_1_ge_90"
    t.integer "percent_2_ge_100"
    t.integer "percent_2_ge_25"
    t.integer "percent_2_ge_50"
    t.integer "percent_2_ge_75"
    t.integer "percent_2_ge_90"
    t.integer "percent_ge_0", null: false
    t.integer "percent_ge_100", null: false
    t.integer "percent_ge_25", null: false
    t.integer "percent_ge_50", null: false
    t.integer "percent_ge_75", null: false
    t.integer "percent_ge_90", null: false
    t.integer "projects_edited"
    t.integer "projects_with_additional_rights"
    t.integer "reactivated_after_reminder", default: 0, null: false
    t.integer "reminders_sent", default: 0, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_since_yesterday", null: false
    t.integer "users"
    t.integer "users_created_since_yesterday"
    t.integer "users_updated_since_yesterday"
    t.integer "users_with_additional_rights"
    t.integer "users_with_gold_projects"
    t.integer "users_with_multiple_projects"
    t.integer "users_with_passing_projects"
    t.integer "users_with_projects"
    t.integer "users_with_silver_projects"
    t.integer "users_without_projects"
    t.index ["created_at"], name: "index_project_stats_on_created_at"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.text "access_continuity_justification"
    t.string "access_continuity_status", default: "?", null: false
    t.text "accessibility_best_practices_justification"
    t.string "accessibility_best_practices_status", default: "?", null: false
    t.text "achieve_passing_justification"
    t.string "achieve_passing_status", default: "Unmet", null: false
    t.text "achieve_silver_justification"
    t.string "achieve_silver_status", default: "Unmet", null: false
    t.datetime "achieved_baseline_1_at"
    t.datetime "achieved_baseline_2_at"
    t.datetime "achieved_baseline_3_at"
    t.datetime "achieved_gold_at", precision: nil
    t.datetime "achieved_passing_at", precision: nil
    t.datetime "achieved_silver_at", precision: nil
    t.text "assurance_case_justification"
    t.string "assurance_case_status", default: "?", null: false
    t.text "automated_integration_testing_justification"
    t.string "automated_integration_testing_status", default: "?", null: false
    t.integer "badge_percentage_0"
    t.integer "badge_percentage_1", default: 0
    t.integer "badge_percentage_2", default: 0
    t.integer "badge_percentage_baseline_1"
    t.integer "badge_percentage_baseline_2"
    t.integer "badge_percentage_baseline_3"
    t.text "build_common_tools_justification"
    t.string "build_common_tools_status", default: "?", null: false
    t.text "build_floss_tools_justification"
    t.string "build_floss_tools_status", default: "?", null: false
    t.text "build_justification"
    t.text "build_non_recursive_justification"
    t.string "build_non_recursive_status", default: "?", null: false
    t.text "build_preserve_debug_justification"
    t.string "build_preserve_debug_status", default: "?", null: false
    t.text "build_repeatable_justification"
    t.string "build_repeatable_status", default: "?", null: false
    t.text "build_reproducible_justification"
    t.string "build_reproducible_status", default: "?", null: false
    t.text "build_standard_variables_justification"
    t.string "build_standard_variables_status", default: "?", null: false
    t.string "build_status", default: "?", null: false
    t.text "bus_factor_justification"
    t.string "bus_factor_status", default: "?", null: false
    t.text "code_of_conduct_justification"
    t.string "code_of_conduct_status", default: "?", null: false
    t.text "code_review_standards_justification"
    t.string "code_review_standards_status", default: "?", null: false
    t.text "coding_standards_enforced_justification"
    t.string "coding_standards_enforced_status", default: "?", null: false
    t.text "coding_standards_justification"
    t.string "coding_standards_status", default: "?", null: false
    t.text "contribution_justification"
    t.text "contribution_requirements_justification"
    t.string "contribution_requirements_status", default: "?", null: false
    t.string "contribution_status", default: "?", null: false
    t.text "contributors_unassociated_justification"
    t.string "contributors_unassociated_status", default: "?", null: false
    t.text "copyright_per_file_justification"
    t.string "copyright_per_file_status", default: "?", null: false
    t.string "cpe"
    t.datetime "created_at", precision: nil, null: false
    t.text "crypto_algorithm_agility_justification"
    t.string "crypto_algorithm_agility_status", default: "?", null: false
    t.text "crypto_call_justification"
    t.string "crypto_call_status", default: "?", null: false
    t.text "crypto_certificate_verification_justification"
    t.string "crypto_certificate_verification_status", default: "?", null: false
    t.text "crypto_credential_agility_justification"
    t.string "crypto_credential_agility_status", default: "?", null: false
    t.text "crypto_floss_justification"
    t.string "crypto_floss_status", default: "?", null: false
    t.text "crypto_keylength_justification"
    t.string "crypto_keylength_status", default: "?", null: false
    t.text "crypto_password_storage_justification"
    t.string "crypto_password_storage_status", default: "?", null: false
    t.text "crypto_pfs_justification"
    t.string "crypto_pfs_status", default: "?", null: false
    t.text "crypto_published_justification"
    t.string "crypto_published_status", default: "?", null: false
    t.text "crypto_random_justification"
    t.string "crypto_random_status", default: "?", null: false
    t.text "crypto_tls12_justification"
    t.string "crypto_tls12_status", default: "?", null: false
    t.text "crypto_used_network_justification"
    t.string "crypto_used_network_status", default: "?", null: false
    t.text "crypto_verification_private_justification"
    t.string "crypto_verification_private_status", default: "?", null: false
    t.text "crypto_weaknesses_justification"
    t.string "crypto_weaknesses_status", default: "?", null: false
    t.text "crypto_working_justification"
    t.string "crypto_working_status", default: "?", null: false
    t.text "dco_justification"
    t.string "dco_status", default: "?", null: false
    t.text "delivery_mitm_justification"
    t.string "delivery_mitm_status", default: "?", null: false
    t.text "delivery_unsigned_justification"
    t.string "delivery_unsigned_status", default: "?", null: false
    t.text "dependency_monitoring_justification"
    t.string "dependency_monitoring_status", default: "?", null: false
    t.text "description"
    t.text "description_good_justification"
    t.string "description_good_status", default: "?", null: false
    t.boolean "disabled_reminders", default: false, null: false
    t.text "discussion_justification"
    t.string "discussion_status", default: "?", null: false
    t.text "documentation_achievements_justification"
    t.string "documentation_achievements_status", default: "?", null: false
    t.text "documentation_architecture_justification"
    t.string "documentation_architecture_status", default: "?", null: false
    t.text "documentation_basics_justification"
    t.string "documentation_basics_status", default: "?", null: false
    t.text "documentation_current_justification"
    t.string "documentation_current_status", default: "?", null: false
    t.text "documentation_interface_justification"
    t.string "documentation_interface_status", default: "?", null: false
    t.text "documentation_quick_start_justification"
    t.string "documentation_quick_start_status", default: "?", null: false
    t.text "documentation_roadmap_justification"
    t.string "documentation_roadmap_status", default: "?", null: false
    t.text "documentation_security_justification"
    t.string "documentation_security_status", default: "?", null: false
    t.text "dynamic_analysis_enable_assertions_justification"
    t.string "dynamic_analysis_enable_assertions_status", default: "?", null: false
    t.text "dynamic_analysis_fixed_justification"
    t.string "dynamic_analysis_fixed_status", default: "?", null: false
    t.text "dynamic_analysis_justification"
    t.string "dynamic_analysis_status", default: "?", null: false
    t.text "dynamic_analysis_unsafe_justification"
    t.string "dynamic_analysis_unsafe_status", default: "?", null: false
    t.text "english_justification"
    t.string "english_status", default: "?", null: false
    t.text "enhancement_responses_justification"
    t.string "enhancement_responses_status", default: "?", null: false
    t.text "external_dependencies_justification"
    t.string "external_dependencies_status", default: "?", null: false
    t.datetime "first_achieved_baseline_1_at"
    t.datetime "first_achieved_baseline_2_at"
    t.datetime "first_achieved_baseline_3_at"
    t.datetime "first_achieved_gold_at", precision: nil
    t.datetime "first_achieved_passing_at", precision: nil
    t.datetime "first_achieved_silver_at", precision: nil
    t.text "floss_license_justification"
    t.text "floss_license_osi_justification"
    t.string "floss_license_osi_status", default: "?", null: false
    t.string "floss_license_status", default: "?", null: false
    t.text "general_comments"
    t.text "governance_justification"
    t.string "governance_status", default: "?", null: false
    t.text "hardened_site_justification"
    t.string "hardened_site_status", default: "?", null: false
    t.text "hardening_justification"
    t.string "hardening_status", default: "?", null: false
    t.string "homepage_url"
    t.text "homepage_url_justification"
    t.string "homepage_url_status", default: "?", null: false
    t.text "implement_secure_design_justification"
    t.string "implement_secure_design_status", default: "?", null: false
    t.string "implementation_languages", default: ""
    t.text "input_validation_justification"
    t.string "input_validation_status", default: "?", null: false
    t.text "installation_common_justification"
    t.string "installation_common_status", default: "?", null: false
    t.text "installation_development_quick_justification"
    t.string "installation_development_quick_status", default: "?", null: false
    t.text "installation_standard_variables_justification"
    t.string "installation_standard_variables_status", default: "?", null: false
    t.text "interact_justification"
    t.string "interact_status", default: "?", null: false
    t.text "interfaces_current_justification"
    t.string "interfaces_current_status", default: "?", null: false
    t.text "internationalization_justification"
    t.string "internationalization_status", default: "?", null: false
    t.text "know_common_errors_justification"
    t.string "know_common_errors_status", default: "?", null: false
    t.text "know_secure_design_justification"
    t.string "know_secure_design_status", default: "?", null: false
    t.datetime "last_reminder_at", precision: nil
    t.string "license"
    t.text "license_location_justification"
    t.string "license_location_status", default: "?", null: false
    t.text "license_per_file_justification"
    t.string "license_per_file_status", default: "?", null: false
    t.integer "lock_version", default: 0
    t.datetime "lost_baseline_1_at"
    t.datetime "lost_baseline_2_at"
    t.datetime "lost_baseline_3_at"
    t.datetime "lost_gold_at", precision: nil
    t.datetime "lost_passing_at", precision: nil
    t.datetime "lost_silver_at", precision: nil
    t.text "maintained_justification"
    t.string "maintained_status", default: "Met", null: false
    t.text "maintenance_or_update_justification"
    t.string "maintenance_or_update_status", default: "?", null: false
    t.string "name"
    t.text "no_leaked_credentials_justification"
    t.string "no_leaked_credentials_status", default: "?", null: false
    t.text "osps_ac_01_01_justification"
    t.string "osps_ac_01_01_status", default: "?"
    t.text "osps_ac_02_01_justification"
    t.string "osps_ac_02_01_status", default: "?"
    t.text "osps_ac_03_01_justification"
    t.string "osps_ac_03_01_status", default: "?"
    t.text "osps_ac_03_02_justification"
    t.string "osps_ac_03_02_status", default: "?"
    t.text "osps_ac_04_01_justification"
    t.string "osps_ac_04_01_status", default: "?"
    t.text "osps_ac_04_02_justification"
    t.string "osps_ac_04_02_status", default: "?"
    t.text "osps_br_01_01_justification"
    t.string "osps_br_01_01_status", default: "?"
    t.text "osps_br_01_02_justification"
    t.string "osps_br_01_02_status", default: "?"
    t.text "osps_br_02_01_justification"
    t.string "osps_br_02_01_status", default: "?"
    t.text "osps_br_02_02_justification"
    t.string "osps_br_02_02_status", default: "?"
    t.text "osps_br_03_01_justification"
    t.string "osps_br_03_01_status", default: "?"
    t.text "osps_br_03_02_justification"
    t.string "osps_br_03_02_status", default: "?"
    t.text "osps_br_04_01_justification"
    t.string "osps_br_04_01_status", default: "?"
    t.text "osps_br_05_01_justification"
    t.string "osps_br_05_01_status", default: "?"
    t.text "osps_br_06_01_justification"
    t.string "osps_br_06_01_status", default: "?"
    t.text "osps_br_07_01_justification"
    t.string "osps_br_07_01_status", default: "?"
    t.text "osps_br_07_02_justification"
    t.string "osps_br_07_02_status", default: "?"
    t.text "osps_do_01_01_justification"
    t.string "osps_do_01_01_status", default: "?"
    t.text "osps_do_02_01_justification"
    t.string "osps_do_02_01_status", default: "?"
    t.text "osps_do_03_01_justification"
    t.string "osps_do_03_01_status", default: "?"
    t.text "osps_do_03_02_justification"
    t.string "osps_do_03_02_status", default: "?"
    t.text "osps_do_04_01_justification"
    t.string "osps_do_04_01_status", default: "?"
    t.text "osps_do_05_01_justification"
    t.string "osps_do_05_01_status", default: "?"
    t.text "osps_do_06_01_justification"
    t.string "osps_do_06_01_status", default: "?"
    t.text "osps_gv_01_01_justification"
    t.string "osps_gv_01_01_status", default: "?"
    t.text "osps_gv_01_02_justification"
    t.string "osps_gv_01_02_status", default: "?"
    t.text "osps_gv_02_01_justification"
    t.string "osps_gv_02_01_status", default: "?"
    t.text "osps_gv_03_01_justification"
    t.string "osps_gv_03_01_status", default: "?"
    t.text "osps_gv_03_02_justification"
    t.string "osps_gv_03_02_status", default: "?"
    t.text "osps_gv_04_01_justification"
    t.string "osps_gv_04_01_status", default: "?"
    t.text "osps_le_01_01_justification"
    t.string "osps_le_01_01_status", default: "?"
    t.text "osps_le_02_01_justification"
    t.string "osps_le_02_01_status", default: "?"
    t.text "osps_le_02_02_justification"
    t.string "osps_le_02_02_status", default: "?"
    t.text "osps_le_03_01_justification"
    t.string "osps_le_03_01_status", default: "?"
    t.text "osps_le_03_02_justification"
    t.string "osps_le_03_02_status", default: "?"
    t.text "osps_qa_01_01_justification"
    t.string "osps_qa_01_01_status", default: "?"
    t.text "osps_qa_01_02_justification"
    t.string "osps_qa_01_02_status", default: "?"
    t.text "osps_qa_02_01_justification"
    t.string "osps_qa_02_01_status", default: "?"
    t.text "osps_qa_02_02_justification"
    t.string "osps_qa_02_02_status", default: "?"
    t.text "osps_qa_03_01_justification"
    t.string "osps_qa_03_01_status", default: "?"
    t.text "osps_qa_04_01_justification"
    t.string "osps_qa_04_01_status", default: "?"
    t.text "osps_qa_04_02_justification"
    t.string "osps_qa_04_02_status", default: "?"
    t.text "osps_qa_05_01_justification"
    t.string "osps_qa_05_01_status", default: "?"
    t.text "osps_qa_05_02_justification"
    t.string "osps_qa_05_02_status", default: "?"
    t.text "osps_qa_06_01_justification"
    t.string "osps_qa_06_01_status", default: "?"
    t.text "osps_qa_06_02_justification"
    t.string "osps_qa_06_02_status", default: "?"
    t.text "osps_qa_06_03_justification"
    t.string "osps_qa_06_03_status", default: "?"
    t.text "osps_qa_07_01_justification"
    t.string "osps_qa_07_01_status", default: "?"
    t.text "osps_sa_01_01_justification"
    t.string "osps_sa_01_01_status", default: "?"
    t.text "osps_sa_02_01_justification"
    t.string "osps_sa_02_01_status", default: "?"
    t.text "osps_sa_03_01_justification"
    t.string "osps_sa_03_01_status", default: "?"
    t.text "osps_sa_03_02_justification"
    t.string "osps_sa_03_02_status", default: "?"
    t.text "osps_vm_01_01_justification"
    t.string "osps_vm_01_01_status", default: "?"
    t.text "osps_vm_02_01_justification"
    t.string "osps_vm_02_01_status", default: "?"
    t.text "osps_vm_03_01_justification"
    t.string "osps_vm_03_01_status", default: "?"
    t.text "osps_vm_04_01_justification"
    t.string "osps_vm_04_01_status", default: "?"
    t.text "osps_vm_04_02_justification"
    t.string "osps_vm_04_02_status", default: "?"
    t.text "osps_vm_05_01_justification"
    t.string "osps_vm_05_01_status", default: "?"
    t.text "osps_vm_05_02_justification"
    t.string "osps_vm_05_02_status", default: "?"
    t.text "osps_vm_05_03_justification"
    t.string "osps_vm_05_03_status", default: "?"
    t.text "osps_vm_06_01_justification"
    t.string "osps_vm_06_01_status", default: "?"
    t.text "osps_vm_06_02_justification"
    t.string "osps_vm_06_02_status", default: "?"
    t.text "regression_tests_added50_justification"
    t.string "regression_tests_added50_status", default: "?", null: false
    t.text "release_notes_justification"
    t.string "release_notes_status", default: "?", null: false
    t.text "release_notes_vulns_justification"
    t.string "release_notes_vulns_status", default: "?", null: false
    t.text "repo_distributed_justification"
    t.string "repo_distributed_status", default: "?", null: false
    t.text "repo_interim_justification"
    t.string "repo_interim_status", default: "?", null: false
    t.text "repo_public_justification"
    t.string "repo_public_status", default: "?", null: false
    t.text "repo_track_justification"
    t.string "repo_track_status", default: "?", null: false
    t.string "repo_url"
    t.datetime "repo_url_updated_at", precision: nil
    t.text "report_archive_justification"
    t.string "report_archive_status", default: "?", null: false
    t.text "report_process_justification"
    t.string "report_process_status", default: "?", null: false
    t.text "report_responses_justification"
    t.string "report_responses_status", default: "?", null: false
    t.text "report_tracker_justification"
    t.string "report_tracker_status", default: "?", null: false
    t.text "report_url_justification"
    t.string "report_url_status", default: "?", null: false
    t.text "require_2FA_justification"
    t.string "require_2FA_status", default: "?", null: false
    t.text "roles_responsibilities_justification"
    t.string "roles_responsibilities_status", default: "?", null: false
    t.text "secure_2FA_justification"
    t.string "secure_2FA_status", default: "?", null: false
    t.text "security_review_justification"
    t.string "security_review_status", default: "?", null: false
    t.text "signed_releases_justification"
    t.string "signed_releases_status", default: "?", null: false
    t.text "sites_https_justification"
    t.string "sites_https_status", default: "?", null: false
    t.text "sites_password_security_justification"
    t.string "sites_password_security_status", default: "?", null: false
    t.text "small_tasks_justification"
    t.string "small_tasks_status", default: "?", null: false
    t.text "static_analysis_common_vulnerabilities_justification"
    t.string "static_analysis_common_vulnerabilities_status", default: "?", null: false
    t.text "static_analysis_fixed_justification"
    t.string "static_analysis_fixed_status", default: "?", null: false
    t.text "static_analysis_justification"
    t.text "static_analysis_often_justification"
    t.string "static_analysis_often_status", default: "?", null: false
    t.string "static_analysis_status", default: "?", null: false
    t.text "test_branch_coverage80_justification"
    t.string "test_branch_coverage80_status", default: "?", null: false
    t.text "test_continuous_integration_justification"
    t.string "test_continuous_integration_status", default: "?", null: false
    t.text "test_invocation_justification"
    t.string "test_invocation_status", default: "?", null: false
    t.text "test_justification"
    t.text "test_most_justification"
    t.string "test_most_status", default: "?", null: false
    t.text "test_policy_justification"
    t.text "test_policy_mandated_justification"
    t.string "test_policy_mandated_status", default: "?", null: false
    t.string "test_policy_status", default: "?", null: false
    t.text "test_statement_coverage80_justification"
    t.string "test_statement_coverage80_status", default: "?", null: false
    t.text "test_statement_coverage90_justification"
    t.string "test_statement_coverage90_status", default: "?", null: false
    t.string "test_status", default: "?", null: false
    t.text "tests_are_added_justification"
    t.string "tests_are_added_status", default: "?", null: false
    t.text "tests_documented_added_justification"
    t.string "tests_documented_added_status", default: "?", null: false
    t.integer "tiered_percentage"
    t.text "two_person_review_justification"
    t.string "two_person_review_status", default: "?", null: false
    t.text "updateable_reused_components_justification"
    t.string "updateable_reused_components_status", default: "?", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.text "version_semver_justification"
    t.string "version_semver_status", default: "?", null: false
    t.text "version_tags_justification"
    t.text "version_tags_signed_justification"
    t.string "version_tags_signed_status", default: "?", null: false
    t.string "version_tags_status", default: "?", null: false
    t.text "version_unique_justification"
    t.string "version_unique_status", default: "?", null: false
    t.text "vulnerabilities_critical_fixed_justification"
    t.string "vulnerabilities_critical_fixed_status", default: "?", null: false
    t.text "vulnerabilities_fixed_60_days_justification"
    t.string "vulnerabilities_fixed_60_days_status", default: "?", null: false
    t.text "vulnerability_report_credit_justification"
    t.string "vulnerability_report_credit_status", default: "?", null: false
    t.text "vulnerability_report_private_justification"
    t.string "vulnerability_report_private_status", default: "?", null: false
    t.text "vulnerability_report_process_justification"
    t.string "vulnerability_report_process_status", default: "?", null: false
    t.text "vulnerability_report_response_justification"
    t.string "vulnerability_report_response_status", default: "?", null: false
    t.text "vulnerability_response_process_justification"
    t.string "vulnerability_response_process_status", default: "?", null: false
    t.text "warnings_fixed_justification"
    t.string "warnings_fixed_status", default: "?", null: false
    t.text "warnings_justification"
    t.string "warnings_status", default: "?", null: false
    t.text "warnings_strict_justification"
    t.string "warnings_strict_status", default: "?", null: false
    t.index ["achieved_gold_at"], name: "index_projects_on_achieved_gold_at"
    t.index ["achieved_passing_at"], name: "index_projects_on_achieved_passing_at"
    t.index ["achieved_silver_at"], name: "index_projects_on_achieved_silver_at"
    t.index ["badge_percentage_0"], name: "index_projects_on_badge_percentage_0"
    t.index ["badge_percentage_1"], name: "index_projects_on_badge_percentage_1"
    t.index ["badge_percentage_2"], name: "index_projects_on_badge_percentage_2"
    t.index ["created_at"], name: "index_projects_on_created_at"
    t.index ["homepage_url"], name: "index_projects_on_homepage_url"
    t.index ["last_reminder_at"], name: "index_projects_on_last_reminder_at"
    t.index ["lost_gold_at"], name: "index_projects_on_lost_gold_at"
    t.index ["lost_passing_at"], name: "index_projects_on_lost_passing_at"
    t.index ["lost_silver_at"], name: "index_projects_on_lost_silver_at"
    t.index ["name"], name: "index_projects_on_name"
    t.index ["repo_url"], name: "index_projects_on_repo_url"
    t.index ["repo_url"], name: "nonempty_repo_urls", unique: true, where: "((repo_url IS NOT NULL) AND ((repo_url)::text <> ''::text))"
    t.index ["tiered_percentage"], name: "index_projects_on_tiered_percentage"
    t.index ["updated_at"], name: "index_projects_on_updated_at"
    t.index ["user_id", "created_at"], name: "index_projects_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.boolean "activated", default: false
    t.datetime "activated_at", precision: nil
    t.string "activation_digest"
    t.datetime "activation_email_sent_at"
    t.boolean "blocked", default: false, null: false
    t.text "blocked_rationale"
    t.datetime "can_login_starting_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.string "email_bidx"
    t.string "encrypted_email"
    t.string "encrypted_email_iv"
    t.datetime "last_login_at", precision: nil
    t.string "name"
    t.string "nickname"
    t.boolean "notification_emails", default: true, null: false
    t.string "password_digest"
    t.string "preferred_locale", default: "en"
    t.string "provider", null: false
    t.string "remember_digest"
    t.string "reset_digest"
    t.datetime "reset_sent_at", precision: nil
    t.string "role"
    t.string "secret_token"
    t.string "uid"
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "use_gravatar", default: false, null: false
    t.string "validation_code"
    t.index ["email_bidx"], name: "email_local_unique_bidx", unique: true, where: "((provider)::text = 'local'::text)"
    t.index ["email_bidx"], name: "index_users_on_email_bidx"
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
    t.index ["uid"], name: "index_users_on_uid"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.integer "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "additional_rights", "projects"
  add_foreign_key "additional_rights", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
