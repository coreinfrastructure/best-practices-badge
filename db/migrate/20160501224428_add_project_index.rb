# frozen_string_literal: true
class AddProjectIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :name
    add_index :projects, :homepage_url
  end
end
