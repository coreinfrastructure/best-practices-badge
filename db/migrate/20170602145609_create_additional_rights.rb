# frozen_string_literal: true

class CreateAdditionalRights < ActiveRecord::Migration[5.1]
  def change
    create_table :additional_rights do |t|
      t.integer :project_id
      t.integer :user_id
      t.index :project_id
      t.index :user_id

      t.timestamps
    end
  end
end
