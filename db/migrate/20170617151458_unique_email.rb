# frozen_string_literal: true

# Force email addresses to be unique if they are local.
# We depend on this, because we use the email address to identify users
# if they are local.  It doesn't matter for non-local users, since we depend
# on that provider to distinguish the users.
class UniqueEmail < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :email, name: 'unique_local_email', unique: true,
                              where: "provider = 'local'"
  end
end
