# frozen_string_literal: true

class ChangeBadgePercentageName < ActiveRecord::Migration[5.0]
  def change
    rename_column :projects, :badge_percentage, :badge_percentage_0
  end
end
