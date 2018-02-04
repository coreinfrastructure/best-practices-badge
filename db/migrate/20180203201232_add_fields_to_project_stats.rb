# frozen_string_literal: true

class AddFieldsToProjectStats < ActiveRecord::Migration[5.1]
  def change
    add_column :project_stats, :users, :integer
    add_column :project_stats, :github_users, :integer
    add_column :project_stats, :local_users, :integer
    add_column :project_stats, :users_created_since_yesterday, :integer
    add_column :project_stats, :users_updated_since_yesterday, :integer
    add_column :project_stats, :users_with_projects, :integer
    add_column :project_stats, :users_without_projects, :integer
    add_column :project_stats, :users_with_multiple_projects, :integer
    add_column :project_stats, :users_with_passing_projects, :integer
    add_column :project_stats, :users_with_silver_projects, :integer
    add_column :project_stats, :users_with_gold_projects, :integer
    add_column :project_stats, :additional_rights_entries, :integer
    add_column :project_stats, :projects_with_additional_rights, :integer
    add_column :project_stats, :users_with_additional_rights, :integer
  end
end
