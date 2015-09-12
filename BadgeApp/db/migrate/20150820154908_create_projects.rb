class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      # Basics
      t.string :name
      t.text :description
      t.string :website
      t.string :license
      # Change Control
      t.string :repo
      t.boolean :changelog
      t.boolean :version_numbering
      # Reporting
      t.string :issue_tracker_url
      # Comments about the projects
      t.text :general_comments

      t.timestamps null: false
    end
  end
end
