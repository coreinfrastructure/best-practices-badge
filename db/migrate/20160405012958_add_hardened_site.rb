# frozen_string_literal: true
class AddHardenedSite < ActiveRecord::Migration
  def change
    add_column :projects, :hardened_site_status, :string, default: '?'
    add_column :projects, :hardened_site_justification, :text
  end
end
