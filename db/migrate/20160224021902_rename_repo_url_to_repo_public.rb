# frozen_string_literal: true
class RenameRepoUrlToRepoPublic < ActiveRecord::Migration
  def change
    rename_column :projects, :repo_url_status, :repo_public_status
    rename_column :projects, :repo_url_justification, :repo_public_justification
  end
end
