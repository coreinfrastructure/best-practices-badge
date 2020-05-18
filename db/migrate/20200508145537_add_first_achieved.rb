# frozen_string_literal: true

# Record when a badge was *first* achieved, ignoring any
# later losses and re-achievements. At this time we won't
# index this, because we're not exposing this to search.
# Right now the goal is to simply record the information,
# because it's easy to get as we go & hard to get later.
# We can always index and make it searchable later.
class AddFirstAchieved < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :first_achieved_passing_at, :datetime
    add_column :projects, :first_achieved_silver_at, :datetime
    add_column :projects, :first_achieved_gold_at, :datetime

    # Lie about it being reversible so this migration can be quietly reversed
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE projects
            SET first_achieved_passing_at = achieved_passing_at
            WHERE achieved_passing_at IS NOT NULL;
        SQL
      end
    end
  end
end
