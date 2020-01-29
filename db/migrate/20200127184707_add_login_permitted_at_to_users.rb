# frozen_string_literal: true

class AddLoginPermittedAtToUsers < ActiveRecord::Migration[5.2]
  def change
    # Null permitted - that means login already permitted
    # If not null, this is the minimum datetime for logins are permitted
    add_column :users, :can_login_starting_at, :datetime
  end
end
