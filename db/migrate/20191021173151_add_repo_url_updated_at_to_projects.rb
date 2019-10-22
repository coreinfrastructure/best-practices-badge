# frozen_string_literal: true

class AddRepoUrlUpdatedAtToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :repo_url_updated_at, :datetime
  end
end
