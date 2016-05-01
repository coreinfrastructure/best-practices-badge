class AddBadgeStatusToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :badge_status, :string
    add_index :projects, :badge_status
  end
end
