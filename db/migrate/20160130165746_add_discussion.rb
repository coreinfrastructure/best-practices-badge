# frozen_string_literal: true
class AddDiscussion < ActiveRecord::Migration
  def change
    add_column :projects, :discussion_status, :string, default: '?'
    add_column :projects, :discussion_justification, :text

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE projects
            SET discussion_status='Met',
                discussion_justification='GitHub issue tracker and pull requests support discussion'
            WHERE project_homepage_url LIKE '%github.com%' OR
                  repo_url LIKE '%github.com%' ;
        SQL
      end
      # dir.down do ...
      # end
    end
  end
end
