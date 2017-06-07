# frozen_string_literal: true

class AddForeignKeyAdditionalRights < ActiveRecord::Migration[5.1]
  def change
    # Modify the additional_rights table to be much pickier about correct
    # data, in particular through foreign key constraints.
    # Many Rails tasks run in parallel, so checks there can be racey.
    # In contrast, putting constraints in the database itself
    # prevents violation of those constraints.

    # Normally in Rails we'd use this to add a reference with a foreign key:
    # # add_reference :uploads, :user, foreign_key: true
    # or use the alise "belongs_to".
    # However, we *already* have columns for user_id and project_id,
    # so we'll just add what we need.
    add_foreign_key :additional_rights, :users
    add_foreign_key :additional_rights, :projects

    # Add other (narrower) constraints
    change_column_null :additional_rights, :user_id, false
    change_column_null :additional_rights, :project_id, false
    add_index :additional_rights, %i[user_id project_id], unique: true
  end
end
