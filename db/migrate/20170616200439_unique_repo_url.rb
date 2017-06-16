# frozen_string_literal: true

# Require repo_url to be unique, but ONLY if it has a non-empty value.

# We don't want people to create many different badge entries for the
# exact same project - they will easily go out of sync.
# Forks are fine, but people can create different badge entries
# for different forks by using different repo URLs.

# We already enforce this in ProjectsController, but that enforcement is
# racey - if different threads or processes do the check at near the same
# time, additional rows can be created.  It is good practice to enforce
# basic database constraints (like this) within the DBMS itself:
# 1. the DMBS can actually *enforce* the requirement (it *does*
# see all records), eliminating the race condition.
# 2. if the rest of the code screws up badly, the DBMS can prevent obviously
# bad data from entering the database.

# We already index repo_url in table projects, but we have to create
# a separate index to implement this constraint.  That's because we
# allow both NULL and 0-length strings, and we don't care if
# 0-length strings are duplicates (that would be unsurprising).
# Instead, we *only* enforce uniqueness if repo_url has a nonzero length.

class UniqueRepoUrl < ActiveRecord::Migration[5.1]
  def change
    condition = "(repo_url IS NOT NULL AND repo_url <> '')"
    add_index :projects, :repo_url, name: 'nonempty_repo_urls', unique: true,
                                    where: condition
  end
end
