# frozen_string_literal: true

# Clean up the values of homepage_url.  Do this as a migration
# so we can do our normal reviews and control delivery of the cleanup.
# This does *not* change the updated_at value of the project, because this
# is considered a database cleanup and *not* a change of the data.
# Cleaning up repo_url values is not so simple, because repo_url must be
# unique (so a simple update could fail).
class CleanupHomepageUrl < ActiveRecord::Migration[5.1]
  def change
    # Lie about it being reversible so it can be quietly reversed
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE projects
            SET homepage_url = TRIM(TRAILING '/' FROM homepage_url)
            WHERE homepage_url LIKE '%/';
        SQL
      end
    end
  end
end
