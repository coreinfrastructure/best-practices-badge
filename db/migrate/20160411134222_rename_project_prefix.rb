# frozen_string_literal: true
class RenameProjectPrefix < ActiveRecord::Migration
  def change
    rename_column :projects,
                  :project_sites_https_status,
                  :sites_https_status
    rename_column :projects,
                  :project_sites_https_justification,
                  :sites_https_justification
    rename_column :projects,
                  :project_homepage_url,
                  :homepage_url
    rename_column :projects,
                  :project_homepage_url_status,
                  :homepage_url_status
    rename_column :projects,
                  :project_homepage_url_justification,
                  :homepage_url_justification
  end
end
