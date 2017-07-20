# frozen_string_literal: true
class AddInstallationCommon < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :installation_common_status, :string, default: '?'
    add_column :projects, :installation_common_justification, :text
  end
end
