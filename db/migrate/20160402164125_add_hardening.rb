# frozen_string_literal: true
class AddHardening < ActiveRecord::Migration
  def change
    add_column :projects, :hardening_status, :string, default: '?'
    add_column :projects, :hardening_justification, :text
  end
end
