# frozen_string_literal: true

class CreateProjectStats < ActiveRecord::Migration
  def change
    create_table :project_stats do |t|
      t.datetime :when
      t.integer :all
      t.integer :percent_ge_25
      t.integer :percent_ge_50
      t.integer :percent_ge_75
      t.integer :percent_ge_90
      t.integer :percent_ge_100

      t.timestamps null: false
    end
  end
end
