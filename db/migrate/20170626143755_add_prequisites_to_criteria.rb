# frozen_string_literal: true

class AddPrequisitesToCriteria < ActiveRecord::Migration[5.1]
  def change
    add_column(
      :projects, :achieve_passing_status, :string, default: 'Unmet',
                                                   null: false
    )
    add_column :projects, :achieve_passing_justification, :text
    add_column(
      :projects, :achieve_silver_status, :string, default: 'Unmet', null: false
    )
    add_column :projects, :achieve_silver_justification, :text
  end
end
