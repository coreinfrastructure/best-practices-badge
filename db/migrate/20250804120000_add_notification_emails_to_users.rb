# frozen_string_literal: true

# Add notification_emails field to users table for unsubscribe functionality
class AddNotificationEmailsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Security: Add notification_emails field with safe default
    add_column :users, :notification_emails, :boolean, default: true, null: false

    # Security: Update all existing users to have notifications enabled by default
    # This is safe as it's an opt-out system
    reversible do |dir|
      dir.up do
        # Update existing users to have notifications enabled
        User.update_all(notification_emails: true)

        # Set notification_emails to false for users who have at least one project
        # with disabled_reminders = true (migrating from project-level to user-level setting)
        User.joins(:projects)
            .where(projects: { disabled_reminders: true })
            .update_all(notification_emails: false)
      end
    end
  end
end
