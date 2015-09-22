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
    t.string   "license_location_status"
    t.text     "license_location_justification"
    t.string   "oss_license_status"
    t.text     "oss_license_justification"
    t.string   "oss_license_osi_status"
    t.text     "oss_license_osi_justification"
    t.text     "general_comments"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
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
