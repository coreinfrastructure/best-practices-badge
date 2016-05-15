# frozen_string_literal: true
class RenameProjectHomepageHttpsToProjectSitesHttps < ActiveRecord::Migration
  def change
    rename_column :projects,
                  :project_homepage_https_status,
                  :project_sites_status
    rename_column :projects,
                  :project_homepage_https_justification,
                  :project_sites_justification
  end
end
