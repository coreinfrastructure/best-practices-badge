# frozen_string_literal: true

class AddLockVersionToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :lock_version, :integer, default: 0
  end
end
