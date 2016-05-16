# frozen_string_literal: true
class CreateNoLeakedCredentials < ActiveRecord::Migration
  def change
    add_column :projects, :no_leaked_credentials_status, :string, default: '?'
    add_column :projects, :no_leaked_credentials_justification, :text

    # We'll assume that if a project is in the current database and
    # they know how to design, they won't do this.
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE projects
            SET no_leaked_credentials_status='Met'
            WHERE know_secure_design_status = 'Met' ;
        SQL
      end
    end
  end
end
