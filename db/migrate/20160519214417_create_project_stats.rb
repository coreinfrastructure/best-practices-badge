# frozen_string_literal: true

class CreateProjectStats < ActiveRecord::Migration
  def change
    create_table :project_stats do |t|
      # The data columns can't be null.  This forces the data to be cleaner,
      # and is a modest performance and space optimization too.
      t.integer :percent_ge_0, null: false
      t.integer :percent_ge_25, null: false
      t.integer :percent_ge_50, null: false
      t.integer :percent_ge_75, null: false
      t.integer :percent_ge_90, null: false
      t.integer :percent_ge_100, null: false
      t.integer :created_since_yesterday, null: false
      t.integer :updated_since_yesterday, null: false

      t.timestamps null: false
    end

    # Optimize performance for sort and lookup by date.
    add_index :project_stats, :created_at
    add_index :projects, :created_at
  end
end
