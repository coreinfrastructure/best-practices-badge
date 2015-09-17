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

ActiveRecord::Schema.define(version: 20150903180310) do

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "project_url"
    t.string   "repo_url"
    t.string   "license"
    t.string   "project_url_status"
    t.text     "project_url_status_justification"
    t.string   "project_url_https_status"
    t.text     "project_url_https_status_justification"
    t.string   "description_sufficient_status"
    t.text     "description_sufficient_status_justification"
    t.string   "interact_status"
    t.text     "interact_status_justification"
    t.string   "contribution_status"
    t.text     "contribution_status_justification"
    t.string   "contribution_criteria_status"
    t.text     "contribution_criteria_status_justification"
    t.string   "license_location"
    t.text     "license_location_justification"
    t.string   "oss_license"
    t.text     "oss_license_justification"
    t.string   "oss_license_osi"
    t.text     "oss_license_osi_justification"
    t.string   "documentation_basics_status"
    t.text     "documentation_basics_status_justification"
    t.string   "documentation_interface_status"
    t.text     "documentation_interface_status_justification"
    t.string   "repo_url_status"
    t.text     "repo_url_status_justification"
    t.string   "repo_track_status"
    t.text     "repo_track_status_justification"
    t.string   "repo_interim_status"
    t.text     "repo_interim_status_justification"
    t.string   "repo_distributed_status"
    t.text     "repo_distributed_status_justification"
    t.string   "version_unique_status"
    t.text     "version_unique_status_justification"
    t.string   "version_semver_status"
    t.text     "version_semver_status_justification"
    t.string   "version_tags_status"
    t.text     "version_tags_status_justification"
    t.string   "changelog_status"
    t.text     "changelog_status_justification"
    t.string   "changelog_vulns_status"
    t.text     "changelog_vulns_status_justification"
    t.text     "general_comments"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "secret_token"
    t.string   "validation_code"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

end
