# frozen_string_literal: true

class AddActivationEmailSentAt < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :activation_email_sent_at, :datetime
  end
end
