# frozen_string_literal: true
class CryptoWeaknessesAlternatives < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :crypto_weaknesses_status, :string, default: '?'
    add_column :projects, :crypto_weaknesses_justification, :text

    add_column :projects, :crypto_alternatives_status, :string, default: '?'
    add_column :projects, :crypto_alternatives_justification, :text
  end
end
