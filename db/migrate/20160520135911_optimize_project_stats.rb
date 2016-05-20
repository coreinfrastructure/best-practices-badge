# frozen_string_literal: true

class OptimizeProjectStats < ActiveRecord::Migration
  def change
    # We don't need these, since the data can't be edited the usual way.
    # We intentionally avoid :created_at, because we don't care about the
    # record creation time, we care about the time the data was sampled.
    remove_column :project_stats, :created_at
    remove_column :project_stats, :updated_at

    # The data columns can't be null.  This forces the data to be cleaner,
    # and is a modest performance and space optimization too.
    change_column_null :project_stats, :when, false
    change_column_null :project_stats, :all, false
    change_column_null :project_stats, :percent_ge_25, false
    change_column_null :project_stats, :percent_ge_50, false
    change_column_null :project_stats, :percent_ge_75, false
    change_column_null :project_stats, :percent_ge_90, false
    change_column_null :project_stats, :percent_ge_100, false

    # Optimize performance for sort and lookup by date.
    add_index :project_stats, :when
  end
end
