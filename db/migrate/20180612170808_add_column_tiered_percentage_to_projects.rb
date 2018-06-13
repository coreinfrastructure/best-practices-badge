# frozen_string_literal: true

class AddColumnTieredPercentageToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :tiered_percentage, :integer
    add_index :projects, :tiered_percentage
    reversible do |dir|
      dir.up do
        # Recalculate the new value directly in the SQL database.
        # It's much faster to do this in the database, and it's easy to do.
        # If badge_percentage_2 is 100, this produces 300% (tiered gold value).
        execute <<-SQL
          UPDATE projects SET tiered_percentage =
            CASE
              WHEN badge_percentage_0 < 100 THEN badge_percentage_0
              WHEN badge_percentage_1 < 100 THEN badge_percentage_1 + 100
              ELSE badge_percentage_2 + 200
            END;
        SQL
      end
    end
  end
end
