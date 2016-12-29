# frozen_string_literal: true

class AddImplementationLanguages < ActiveRecord::Migration
  def change
    add_column :projects, :implementation_languages, :string, default: ''
  end
end
