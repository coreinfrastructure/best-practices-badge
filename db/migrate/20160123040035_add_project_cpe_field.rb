# frozen_string_literal: true
class AddProjectCpeField < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :cpe, :string
  end
end
