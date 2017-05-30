# frozen_string_literal: true

class AddAssuranceCase < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :assurance_case_status, :string, default: '?'
    add_column :projects, :assurance_case_justification, :text
  end
end
