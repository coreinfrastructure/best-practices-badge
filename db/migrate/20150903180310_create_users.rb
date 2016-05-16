# frozen_string_literal: true
class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :name
      t.string :nickname
      t.string :email
      t.string :password_digest
      t.string :secret_token
      t.string :validation_code
      t.timestamps null: false
    end
  end
end
