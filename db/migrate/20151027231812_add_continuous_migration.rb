# frozen_string_literal: true
class AddContinuousMigration < ActiveRecord::Migration
  def change
    add_column :projects, :test_continuous_integration_status, :string, default: '?'
    add_column :projects, :test_continuous_integration_justification, :text
  end
end
