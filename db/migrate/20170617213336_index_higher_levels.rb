# frozen_string_literal: true

class IndexHigherLevels < ActiveRecord::Migration[5.1]
  def change
    add_index :projects, :badge_percentage_1
    add_index :projects, :badge_percentage_2
  end
end
