class ChangeEmailColumnType < ActiveRecord::Migration
  def up
    enable_extension 'citext'

    change_column :users, :email, :citext
  end

  def down
    change_column :users, :email, :string

    disable_extension 'citext'
  end
end
