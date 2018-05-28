# frozen_string_literal: true

class AddUseGravatar < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :use_gravatar, :boolean, default: false, null: false
  end
end
