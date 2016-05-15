# frozen_string_literal: true
class AddActivationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :activation_digest, :string
    add_column :users, :activated, :boolean, default: false
    add_column :users, :activated_at, :datetime

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users
            SET activated='t';
        SQL
      end
    end
  end
end
