# frozen_string_literal: true
# Copyright the Linux Foundation and OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Make it possible to identify blocked user accounts and a rationale
# (why they were blocked, typically with the date of getting blocked)

class AddBlockedToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :blocked, :boolean, null: false, default: false
    add_column :users, :blocked_rationale, :text
  end
end
