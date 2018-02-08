# frozen_string_literal: true

# Clean up repo URLs.  This is slightly trickier because repo_urls,
# if present, must be unique in the database.
# This cleanup changes the repo_urls, but *only* if the cleaned-up version
# isn't there already.  This solves 47/49 entries, and we can deal
# with the last 2 separately (if we need to).  Those last 2 entries are:
# - 1268 | https://github.com/linkerd/linkerd/
# - 54 | https://git.openssl.org/
# The openSSL one involves a historical entry we might just permit
# permanently.

class CleanupRepoUrl < ActiveRecord::Migration[5.1]
  def change
    # Lie about it being reversible so it can be quietly reversed
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE projects
            SET repo_url = TRIM(TRAILING '/' FROM repo_url)
            WHERE repo_url LIKE '%/' AND
                  TRIM(TRAILING '/' FROM repo_url) NOT IN
                  (SELECT repo_url FROM projects);
        SQL
      end
    end
  end
end
