# frozen_string_literal: true

class AddSilverAt < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :achieved_silver_at, :datetime
    add_index :projects, :achieved_silver_at
    add_column :projects, :lost_silver_at, :datetime
    add_index :projects, :lost_silver_at

    add_column :projects, :achieved_gold_at, :datetime
    add_index :projects, :achieved_gold_at
    add_column :projects, :lost_gold_at, :datetime
    add_index :projects, :lost_gold_at
  end
end
