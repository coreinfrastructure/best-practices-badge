# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160902221520) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"

  create_table "pg_search_documents", force: :cascade do |t|
    t.text     "content"
    t.integer  "searchable_id"
    t.string   "searchable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "pg_search_documents", ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id", using: :btree

  create_table "project_stats", force: :cascade do |t|
    t.integer  "percent_ge_0",            null: false
    t.integer  "percent_ge_25",           null: false
    t.integer  "percent_ge_50",           null: false
    t.integer  "percent_ge_75",           null: false
    t.integer  "percent_ge_90",           null: false
    t.integer  "percent_ge_100",          null: false
    t.integer  "created_since_yesterday", null: false
    t.integer  "updated_since_yesterday", null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "project_stats", ["created_at"], name: "index_project_stats_on_created_at", using: :btree

  create_table "projects", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.string   "homepage_url"
    t.string   "repo_url"
    t.string   "license"
    t.string   "homepage_url_status",                                  default: "?"
    t.text     "homepage_url_justification"
    t.string   "sites_https_status",                                   default: "?"
    t.text     "sites_https_justification"
    t.string   "description_good_status",                              default: "?"
    t.text     "description_good_justification"
    t.string   "interact_status",                                      default: "?"
    t.text     "interact_justification"
    t.string   "contribution_status",                                  default: "?"
    t.text     "contribution_justification"
    t.string   "contribution_requirements_status",                     default: "?"
    t.text     "contribution_requirements_justification"
    t.string   "license_location_status",                              default: "?"
    t.text     "license_location_justification"
    t.string   "floss_license_status",                                 default: "?"
    t.text     "floss_license_justification"
    t.string   "floss_license_osi_status",                             default: "?"
    t.text     "floss_license_osi_justification"
    t.string   "documentation_basics_status",                          default: "?"
    t.text     "documentation_basics_justification"
    t.string   "documentation_interface_status",                       default: "?"
    t.text     "documentation_interface_justification"
    t.string   "repo_public_status",                                   default: "?"
    t.text     "repo_public_justification"
    t.string   "repo_track_status",                                    default: "?"
    t.text     "repo_track_justification"
    t.string   "repo_interim_status",                                  default: "?"
    t.text     "repo_interim_justification"
    t.string   "repo_distributed_status",                              default: "?"
    t.text     "repo_distributed_justification"
    t.string   "version_unique_status",                                default: "?"
    t.text     "version_unique_justification"
    t.string   "version_semver_status",                                default: "?"
    t.text     "version_semver_justification"
    t.string   "version_tags_status",                                  default: "?"
    t.text     "version_tags_justification"
    t.string   "release_notes_status",                                 default: "?"
    t.text     "release_notes_justification"
    t.string   "release_notes_vulns_status",                           default: "?"
    t.text     "release_notes_vulns_justification"
    t.string   "report_url_status",                                    default: "?"
    t.text     "report_url_justification"
    t.string   "report_tracker_status",                                default: "?"
    t.text     "report_tracker_justification"
    t.string   "report_process_status",                                default: "?"
    t.text     "report_process_justification"
    t.string   "report_responses_status",                              default: "?"
    t.text     "report_responses_justification"
    t.string   "enhancement_responses_status",                         default: "?"
    t.text     "enhancement_responses_justification"
    t.string   "report_archive_status",                                default: "?"
    t.text     "report_archive_justification"
    t.string   "vulnerability_report_process_status",                  default: "?"
    t.text     "vulnerability_report_process_justification"
    t.string   "vulnerability_report_private_status",                  default: "?"
    t.text     "vulnerability_report_private_justification"
    t.string   "vulnerability_report_response_status",                 default: "?"
    t.text     "vulnerability_report_response_justification"
    t.string   "build_status",                                         default: "?"
    t.text     "build_justification"
    t.string   "build_common_tools_status",                            default: "?"
    t.text     "build_common_tools_justification"
    t.string   "build_floss_tools_status",                             default: "?"
    t.text     "build_floss_tools_justification"
    t.string   "test_status",                                          default: "?"
    t.text     "test_justification"
    t.string   "test_invocation_status",                               default: "?"
    t.text     "test_invocation_justification"
    t.string   "test_most_status",                                     default: "?"
    t.text     "test_most_justification"
    t.string   "test_policy_status",                                   default: "?"
    t.text     "test_policy_justification"
    t.string   "tests_are_added_status",                               default: "?"
    t.text     "tests_are_added_justification"
    t.string   "tests_documented_added_status",                        default: "?"
    t.text     "tests_documented_added_justification"
    t.string   "warnings_status",                                      default: "?"
    t.text     "warnings_justification"
    t.string   "warnings_fixed_status",                                default: "?"
    t.text     "warnings_fixed_justification"
    t.string   "warnings_strict_status",                               default: "?"
    t.text     "warnings_strict_justification"
    t.string   "know_secure_design_status",                            default: "?"
    t.text     "know_secure_design_justification"
    t.string   "know_common_errors_status",                            default: "?"
    t.text     "know_common_errors_justification"
    t.string   "crypto_published_status",                              default: "?"
    t.text     "crypto_published_justification"
    t.string   "crypto_call_status",                                   default: "?"
    t.text     "crypto_call_justification"
    t.string   "crypto_floss_status",                                  default: "?"
    t.text     "crypto_floss_justification"
    t.string   "crypto_keylength_status",                              default: "?"
    t.text     "crypto_keylength_justification"
    t.string   "crypto_working_status",                                default: "?"
    t.text     "crypto_working_justification"
    t.string   "crypto_pfs_status",                                    default: "?"
    t.text     "crypto_pfs_justification"
    t.string   "crypto_password_storage_status",                       default: "?"
    t.text     "crypto_password_storage_justification"
    t.string   "crypto_random_status",                                 default: "?"
    t.text     "crypto_random_justification"
    t.string   "delivery_mitm_status",                                 default: "?"
    t.text     "delivery_mitm_justification"
    t.string   "delivery_unsigned_status",                             default: "?"
    t.text     "delivery_unsigned_justification"
    t.string   "vulnerabilities_fixed_60_days_status",                 default: "?"
    t.text     "vulnerabilities_fixed_60_days_justification"
    t.string   "vulnerabilities_critical_fixed_status",                default: "?"
    t.text     "vulnerabilities_critical_fixed_justification"
    t.string   "static_analysis_status",                               default: "?"
    t.text     "static_analysis_justification"
    t.string   "static_analysis_common_vulnerabilities_status",        default: "?"
    t.text     "static_analysis_common_vulnerabilities_justification"
    t.string   "static_analysis_fixed_status",                         default: "?"
    t.text     "static_analysis_fixed_justification"
    t.string   "static_analysis_often_status",                         default: "?"
    t.text     "static_analysis_often_justification"
    t.string   "dynamic_analysis_status",                              default: "?"
    t.text     "dynamic_analysis_justification"
    t.string   "dynamic_analysis_unsafe_status",                       default: "?"
    t.text     "dynamic_analysis_unsafe_justification"
    t.string   "dynamic_analysis_enable_assertions_status",            default: "?"
    t.text     "dynamic_analysis_enable_assertions_justification"
    t.string   "dynamic_analysis_fixed_status",                        default: "?"
    t.text     "dynamic_analysis_fixed_justification"
    t.text     "general_comments"
    t.datetime "created_at",                                                           null: false
    t.datetime "updated_at",                                                           null: false
    t.string   "crypto_weaknesses_status",                             default: "?"
    t.text     "crypto_weaknesses_justification"
    t.string   "test_continuous_integration_status",                   default: "?"
    t.text     "test_continuous_integration_justification"
    t.string   "cpe"
    t.string   "discussion_status",                                    default: "?"
    t.text     "discussion_justification"
    t.string   "no_leaked_credentials_status",                         default: "?"
    t.text     "no_leaked_credentials_justification"
    t.string   "english_status",                                       default: "?"
    t.text     "english_justification"
    t.string   "hardening_status",                                     default: "?"
    t.text     "hardening_justification"
    t.string   "crypto_used_network_status",                           default: "?"
    t.text     "crypto_used_network_justification"
    t.string   "crypto_tls12_status",                                  default: "?"
    t.text     "crypto_tls12_justification"
    t.string   "crypto_certificate_verification_status",               default: "?"
    t.text     "crypto_certificate_verification_justification"
    t.string   "crypto_verification_private_status",                   default: "?"
    t.text     "crypto_verification_private_justification"
    t.string   "hardened_site_status",                                 default: "?"
    t.text     "hardened_site_justification"
    t.string   "installation_common_status",                           default: "?"
    t.text     "installation_common_justification"
    t.string   "build_reproducible_status",                            default: "?"
    t.text     "build_reproducible_justification"
    t.integer  "badge_percentage"
    t.datetime "achieved_passing_at"
    t.datetime "lost_passing_at"
    t.datetime "last_reminder_at"
    t.boolean  "disabled_reminders",                                   default: false, null: false
  end

  add_index "projects", ["achieved_passing_at"], name: "index_projects_on_achieved_passing_at", using: :btree
  add_index "projects", ["badge_percentage"], name: "index_projects_on_badge_percentage", using: :btree
  add_index "projects", ["created_at"], name: "index_projects_on_created_at", using: :btree
  add_index "projects", ["homepage_url"], name: "index_projects_on_homepage_url", using: :btree
  add_index "projects", ["last_reminder_at"], name: "index_projects_on_last_reminder_at", using: :btree
  add_index "projects", ["lost_passing_at"], name: "index_projects_on_lost_passing_at", using: :btree
  add_index "projects", ["name"], name: "index_projects_on_name", using: :btree
  add_index "projects", ["repo_url"], name: "index_projects_on_repo_url", using: :btree
  add_index "projects", ["updated_at"], name: "index_projects_on_updated_at", using: :btree
  add_index "projects", ["user_id", "created_at"], name: "index_projects_on_user_id_and_created_at", using: :btree
  add_index "projects", ["user_id"], name: "index_projects_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "nickname"
    t.string   "email"
    t.string   "password_digest"
    t.string   "secret_token"
    t.string   "validation_code"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "role"
    t.string   "remember_digest"
    t.string   "activation_digest"
    t.boolean  "activated",         default: false
    t.datetime "activated_at"
    t.string   "reset_digest"
    t.datetime "reset_sent_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  add_foreign_key "projects", "users"
end
