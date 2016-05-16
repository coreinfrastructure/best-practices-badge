# frozen_string_literal: true
class AddBuildReproducible < ActiveRecord::Migration
  def change
    add_column :projects, :build_reproducible_status, :string, default: '?'
    add_column :projects, :build_reproducible_justification, :text
  end
end
