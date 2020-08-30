# frozen_string_literal: true

class AddEncryptedEmailToUsers < ActiveRecord::Migration[5.1]
  def change
    # Hold onto the old data for a bit, because it's precious.
    # Once we're confident things are okay, we'll delete this field
    # in a separate operation.
    rename_column :users, :email, :unencrypted_email

    # Add columns to encrypt email addresses
    add_column :users, :encrypted_email, :string
    add_column :users, :encrypted_email_iv, :string

    # Add columns for blind indexes of email addresses
    add_column :users, :encrypted_email_bidx, :string
    add_index :users, :encrypted_email_bidx
    # The following replaces the old 'unique_local_email_hash'.
    # For *local* accounts we must have *unique* email addresses - enforce
    # this in the database system itself, to prevent race conditions.
    add_index :users, :encrypted_email_bidx,
              name: 'encrypted_email_local_unique_bidx',
              unique: true,
              where: "provider = 'local'"
    # This is reversible, in the sense that we don't need to do anything
    # special to undo it.
    reversible do |dir|
      dir.up do
        # It would be *MUCH* faster to tell the database to
        # directly calculate the new columns, like this:
        # execute <<-SQL
        # UPDATE users SET encrypted_email = ..., ... ;
        # SQL
        # However, that would require us to send the secret keys to the
        # database, where they could be logged or recorded.  We expressly
        # want to *never* send the database our secret keys.
        # So we'll do a (slow) Ruby loop instead.
        # This loop only happens once, during the migration, so it's
        # not a big deal that it's slow, and find_each helps.
        # Migrations on PostgreSQL happen within a transaction, so this
        # is a one-time atomic operation.
        User.reset_column_information # Ensure column info is current
        User.find_each do |user|
          next if user.unencrypted_email.blank? # skip if nothing to encrypt

          user.name = '-' unless user.name? # Won't save if blank
          user.email = user.unencrypted_email # encrypt & index the email
          user.save!
        end
      end
    end
  end
end
