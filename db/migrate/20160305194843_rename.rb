# frozen_string_literal: true
class Rename < ActiveRecord::Migration
  def change
    rename_column :projects,
                  :description_sufficient_status,
                  :description_good_status
    rename_column :projects,
                  :description_sufficient_justification,
                  :description_good_justification
  end
end
