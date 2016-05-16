# frozen_string_literal: true
class RenameProjectUrl < ActiveRecord::Migration
  def change
    # rename_column :projects, :old_column, :new_column
    rename_column :projects, :project_url, :project_homepage_url

    rename_column :projects, :project_url_status, :project_homepage_url_status
    rename_column :projects, :project_url_justification,
                  :project_homepage_url_justification

    rename_column :projects, :project_url_https_status,
                  :project_homepage_https_status
    rename_column :projects, :project_url_https_justification,
                  :project_homepage_https_justification
  end
end
