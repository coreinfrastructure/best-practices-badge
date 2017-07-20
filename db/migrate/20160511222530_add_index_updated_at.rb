# frozen_string_literal: true
class AddIndexUpdatedAt < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :updated_at
  end
end
