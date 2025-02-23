# frozen_string_literal: true

class RenameForbiddenToForbiddenHashInBadPasswords < ActiveRecord::Migration[8.0]
  def change
    # Because we're *renaming* a column, the index will continue to exist
    rename_column :bad_passwords, 'forbidden', 'forbidden_hash'
    puts 'Remember to run: rake update_bad_password_db'
  end
end
