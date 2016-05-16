# frozen_string_literal: true
class AddIndexUpdatedAt < ActiveRecord::Migration
  def change
    add_index :projects, :updated_at
  end
end
