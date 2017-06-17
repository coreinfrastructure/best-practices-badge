# frozen_string_literal: true

# Record progress in higher levels
class RecordHigherLevels < ActiveRecord::Migration[5.1]
  def change
    # progress in silver
    add_column :project_stats, :percent_1_ge_25, :integer
    add_column :project_stats, :percent_1_ge_50, :integer
    add_column :project_stats, :percent_1_ge_75, :integer
    add_column :project_stats, :percent_1_ge_90, :integer
    add_column :project_stats, :percent_1_ge_100, :integer

    # progress in gold
    add_column :project_stats, :percent_2_ge_25, :integer
    add_column :project_stats, :percent_2_ge_50, :integer
    add_column :project_stats, :percent_2_ge_75, :integer
    add_column :project_stats, :percent_2_ge_90, :integer
    add_column :project_stats, :percent_2_ge_100, :integer
  end
end
