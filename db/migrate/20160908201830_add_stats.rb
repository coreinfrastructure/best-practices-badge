# frozen_string_literal: true

class AddStats < ActiveRecord::Migration[4.2]
  def change
    # Number of reminders sent within 24 hours
    add_column :project_stats, :reminders_sent, :integer,
               null: false, default: 0

    # Projects that were sent a reminder, and have had an update since,
    # within a fixed period of time.
    add_column :project_stats, :reactivated_after_reminder, :integer,
               null: false, default: 0

    # Number of projects that have received an update within 30 days.
    # It's hard to capture information after the fact,
    # so we'll leave entries null when we don't know their values.
    add_column :project_stats, :active_projects, :integer, null: true

    # Number of projects that have received an update within 30 days
    # and are not at 100%.
    # It's hard to capture "active in progress" information after the fact,
    # so we'll leave entries null when we don't know their values.
    add_column :project_stats, :active_in_progress, :integer, null: true
  end
end
