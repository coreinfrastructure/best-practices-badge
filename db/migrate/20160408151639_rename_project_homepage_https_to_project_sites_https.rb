# frozen_string_literal: true
class RenameProjectHomepageHttpsToProjectSitesHttps < ActiveRecord::Migration[4.2]
  def change
    rename_column :projects,
                  :project_homepage_https_status,
                  :project_sites_status
    rename_column :projects,
                  :project_homepage_https_justification,
                  :project_sites_justification
  end
end
