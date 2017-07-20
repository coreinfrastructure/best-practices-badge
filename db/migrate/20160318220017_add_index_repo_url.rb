# frozen_string_literal: true
class AddIndexRepoUrl < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :repo_url
  end
end
