# frozen_string_literal: true
class ChangeEmailColumnType < ActiveRecord::Migration[4.2]
  # Change user email to citext this is not reversible so must use
  # up/down instead of change.
  def up
    enable_extension 'citext'

    change_column :users, :email, :citext
  end

  def down
    change_column :users, :email, :string

    disable_extension 'citext'
  end
end
