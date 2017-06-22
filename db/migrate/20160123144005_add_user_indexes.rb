# frozen_string_literal: true
class AddUserIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :uid
    add_index :users, :email
  end
end
