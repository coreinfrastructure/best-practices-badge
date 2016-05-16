# frozen_string_literal: true
class AddIndexRepoUrl < ActiveRecord::Migration
  def change
    add_index :projects, :repo_url
  end
end
