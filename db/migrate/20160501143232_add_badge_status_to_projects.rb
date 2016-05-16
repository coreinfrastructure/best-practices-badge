# frozen_string_literal: true
class AddBadgeStatusToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :badge_status, :string
    add_index :projects, :badge_status
    Project.find_each do |project|
      project.update_badge_status
      project.save!(validate: false)
    end
  end

  def down
    remove_index :projects, :badge_status
    remove_column :projects, :badge_status
  end
end
