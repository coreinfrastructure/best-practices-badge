# frozen_string_literal: true

class RemoveUnencryptedEmailFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_index :users,
                 column: 'unencrypted_email',
                 name: 'index_users_on_unencrypted_email'
    remove_index :users,
                 column: 'unencrypted_email',
                 name: 'unique_local_email', unique: true,
                 where: "((provider)::text = 'local'::text)"
    remove_column :users, :unencrypted_email, :citext
  end
end
