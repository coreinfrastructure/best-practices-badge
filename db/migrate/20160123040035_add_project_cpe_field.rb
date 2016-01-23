class AddProjectCpeField < ActiveRecord::Migration
  def change
    add_column :projects, :cpe, :string
  end
end
