# frozen_string_literal: true

class AddLoginAtToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :last_login_at, :datetime
    add_index :users, :last_login_at
  end
end
