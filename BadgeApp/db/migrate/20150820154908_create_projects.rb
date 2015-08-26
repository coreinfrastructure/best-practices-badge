class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.string :description
      t.string :website
      t.string :license
      t.string :repo

      t.timestamps null: false
    end
  end
end
