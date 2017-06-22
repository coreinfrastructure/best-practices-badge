# frozen_string_literal: true

class AddTransitionDatetimes < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :achieved_passing_at, :datetime
    add_column :projects, :lost_passing_at, :datetime
  end
end
