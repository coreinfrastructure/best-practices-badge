# frozen_string_literal: true

# Add fields to support sending reminders to inactive badging projects.
class Reminders < ActiveRecord::Migration
  def change
    add_column :projects, :last_reminder_at, :datetime
    add_index :projects, :last_reminder_at
    add_column :projects, :disabled_reminders, :boolean, default: false
    change_column_null :projects, :disabled_reminders, false
    add_index :projects, :lost_passing_at
  end
end
