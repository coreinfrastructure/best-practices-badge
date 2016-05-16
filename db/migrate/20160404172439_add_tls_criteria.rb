# frozen_string_literal: true
class AddTlsCriteria < ActiveRecord::Migration
  def change
    add_column :projects, :crypto_used_network_status, :string, default: '?'
    add_column :projects, :crypto_used_network_justification, :text

    add_column :projects, :crypto_tls12_status, :string, default: '?'
    add_column :projects, :crypto_tls12_justification, :text

    add_column :projects,
               :crypto_certificate_verification_status, :string, default: '?'
    add_column :projects, :crypto_certificate_verification_justification, :text

    add_column :projects,
               :crypto_verification_private_status, :string, default: '?'
    add_column :projects, :crypto_verification_private_justification, :text
  end
end
