# frozen_string_literal: true

# Add columns for storing hashed and encrypted user email addresses.

class EncryptEmailAddresses < ActiveRecord::Migration[5.1]
  def change
    # This migration does NOT delete the old "email" field,
    # because that is precious data. We don't want to delete that field
    # until we're sure that nothing will be lost.
    # Instead, we rename it so that we can tell if any code depends
    # on the old field.
    rename_column :users, :email, :email_unencrypted
    # email_hash supports case-insensitive email lookup
    add_column :users, :email_hash, :string
    # email_encrypted supports sending email to case-sensitive addresses
    add_column :users, :email_encrypted, :string
    add_index :users, :email_hash
    add_index :users, :email_hash,
              name: 'unique_local_email_hash',
              unique: true,
              where: "provider = 'local'"
    # This is reversible, in the sense that we don't need to do anything
    # special to undo it.
    reversible do |dir|
      dir.up do
        # It would be *MUCH* faster to tell the database to
        # directly calculate the new columns, like this:
        # execute <<-SQL
        # UPDATE users SET email_encrypted = ..., email_hash = ... ;
        # SQL
        # However, that would require us to send the secret keys to the
        # database, where they could be logged or recorded.  We expressly
        # want to *never* send the database our secret keys.
        # So we'll do a (slow) Ruby loop instead.
        # This loop only happens once, during the migration, so it's
        # not a big deal that it's slow, and find_each helps.
        User.find_each do |user|
          next if user.email_unencrypted.blank?
          user.name = '-' unless user.name? # Won't save otherwise
          user.email_hash = User.compute_email_hash(user.email_unencrypted)
          user.email_encrypted = User.compute_email_encrypted(
            user.email_unencrypted
          )
          user.save!
        end
      end
    end
  end
end
