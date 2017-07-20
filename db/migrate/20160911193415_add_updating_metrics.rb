# frozen_string_literal: true

class AddUpdatingMetrics < ActiveRecord::Migration[4.2]
  def change
    # Add metrics recording project counts where created_at < updated_at.
    # A lot of projects get started and don't edit later - we'd like to
    # record how many make further progress.

    # Total projects where created_at < updated_at.  This will be
    # <= percent_ge_0 (the set of all projects).
    add_column :project_stats, :projects_edited, :integer, null: true

    # Number of projects that have received an update within 30 days
    # and created_at < updated_at
    # It's hard to capture information after the fact,
    # so we'll leave entries null when we don't know their values.
    add_column :project_stats, :active_edited_projects, :integer, null: true

    # Number of projects that have received an update within 30 days
    # and are not at 100%, and created_at < updated_at.
    # It's hard to capture "active in progress" information after the fact,
    # so we'll leave entries null when we don't know their values.
    add_column :project_stats, :active_edited_in_progress, :integer, null: true
  end
end
