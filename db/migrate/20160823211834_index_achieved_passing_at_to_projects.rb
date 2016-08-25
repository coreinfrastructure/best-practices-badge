# frozen_string_literal: true
class IndexAchievedPassingAtToProjects < ActiveRecord::Migration
  def change
    add_index :projects, :achieved_passing_at
  end
end
