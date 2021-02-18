# frozen_string_literal: true

# Migrate to the use of gem blind_index version 2.2, which
# has somewhat different conventions than its old version.
# In particular, its default column names have changed.
# We're changing the cryptographic hash algorithm
# (to its new default argon2id),
# so there's no need to keep the old hash values.
# Instead, we destroy the old columns & blind indexes,
# create the new ones, and backfill the data (a forced recalculation).
# The backfill takes some time, but it's a one-time operation.
#
# To see how we used to do this, see:
# db/migrate/20180525145445_add_encrypted_email_to_users.rb
# db/migrate/20161102170815_change_email_column_type.rb

class BlindIndex22 < ActiveRecord::Migration[6.1]
  def change
    rename_column :users, :encrypted_email_bidx, :email_bidx

    # This rename is done automatically by rename_column:
    # rename_index :users, 'index_users_on_encrypted_email_bidx',
    #              'index_users_on_email_bidx'

    rename_index :users, 'encrypted_email_local_unique_bidx',
                 'email_local_unique_bidx'

    # Backfill (recompute) the blind index. This is relatively quick;
    # one test took 1m13s for 8999 users.
    reversible do |dir|
      # Update the blind index value "by hand", as
      # this doesn't update it properly: BlindIndex.backfill(User)
      User.find_each(batch_size: 400) do |user|
        # puts(user.id)
        if user.email.present?
          user.email_bidx = User.generate_email_bidx(user.email)
          # Do NOT change the changed timestamp, as this encryption change
          # is an internal issue. Also, disable validations (e.g., blank names)
          # since while that's not desirable we need to do the transition
          # for all records, even less-than-perfect ones.
          user.save!(touch: false, validate: false)
        end
      end
    end
  end
end
