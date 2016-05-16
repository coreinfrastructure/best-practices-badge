# frozen_string_literal: true
class BadgeStatusToPercentage < ActiveRecord::Migration
  def up
    rename_column :projects, :badge_status, :badge_percentage
    Project.find_each do |project|
      project.update_badge_percentage
      project.save!(validate: false)
    end
    change_column :projects, :badge_percentage,
                  'integer USING CAST("badge_percentage" AS integer)'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
