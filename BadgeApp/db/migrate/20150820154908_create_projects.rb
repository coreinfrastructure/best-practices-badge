class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
    # OSS PROJECT BASICS
      # Identification
      t.string :name
      t.text :description
      t.string :project_url
      t.string :repo_url
      t.string :license
=begin
      # Project Website
      t.string :project_url_status
      t.text :project_url_status_justification
      t.string :project_url_https_status
      t.text :project_url_https_status_justification
      # Basic Project Website Content
      t.string :description_sufficient_status
      t.text :description_sufficient_status_justification
      t.string :interact_status
      t.text :interact_status_justification
      t.string :contribution_status
      t.text :contribution_status_justification
      t.string :contribution_criteria_status
      t.text :contribution_criteria_status_justification
=end
      # OSS License
      t.string :license_location_status
      t.text :license_location_justification
      t.string :oss_license_status
      t.text :oss_license_justification
      t.string :oss_license_osi_status
      t.text :oss_license_osi_justification
=begin
# Documentation
      t.string :documentation_basics_status
      t.text :documentation_basics_status_justification
      t.string :documentation_interface_status
      t.text :documentation_interface_status_justification
    # CHANGE CONTROL
      # Public version-controlled source repository
      t.string :repo_url_status
      t.text :repo_url_status_justification
      t.string :repo_track_status
      t.text :repo_track_status_justification
      t.string :repo_interim_status
      t.text :repo_interim_status_justification
      t.string :repo_distributed_status
      t.text :repo_distributed_status_justification
      # Unique version numbering
      t.string :version_unique_status
      t.text :version_unique_status_justification
      t.string :version_semver_status
      t.text :version_semver_status_justification
      t.string :version_tags_status
      t.text :version_tags_status_justification
      # ChangeLog
      t.string :changelog_status
      t.text :changelog_status_justification
      t.string :changelog_vulns_status
      t.text :changelog_vulns_status_justification
=end
    # COMMENTS ABOUT THE PROJECT
      t.text :general_comments

      t.timestamps null: false
    end
  end
end
