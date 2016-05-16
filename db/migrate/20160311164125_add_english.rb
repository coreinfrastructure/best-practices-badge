# frozen_string_literal: true
class AddEnglish < ActiveRecord::Migration
  def change
    add_column :projects, :english_status, :string, default: '?'
    add_column :projects, :english_justification, :text

    # Since the badge criteria are only in English, it's pretty likely
    # that existing projects already meet this criterion.
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE projects SET english_status='Met';
        SQL
      end
    end
  end
end
