# frozen_string_literal: true
class IndexAchievedPassingAtToProjects < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :achieved_passing_at
  end
end
