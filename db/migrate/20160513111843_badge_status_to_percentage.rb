class BadgeStatusToPercentage < ActiveRecord::Migration
  def up
    rename_column :projects, :badge_status, :badge_percentage
    Project.find_each do |project|
      project.update_badge_percentage
      project.save!(validate: false)
    end
    change_column :projects, :badge_status,
                  'integer USING CAST("badge_status" AS integer)'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
