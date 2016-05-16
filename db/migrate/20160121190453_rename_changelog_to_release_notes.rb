# frozen_string_literal: true
class RenameChangelogToReleaseNotes < ActiveRecord::Migration
  def change
    rename_column :projects, :changelog_status,
                  :release_notes_status
    rename_column :projects, :changelog_justification,
                  :release_notes_justification
    rename_column :projects, :changelog_vulns_status,
                  :release_notes_vulns_status
    rename_column :projects, :changelog_vulns_justification,
                  :release_notes_vulns_justification
  end
end
