# frozen_string_literal: true

class AddLockVersionToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :lock_version, :integer, default: 0
  end
end
