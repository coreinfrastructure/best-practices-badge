# frozen_string_literal: true

class ProjectStat < ActiveRecord::Base
  STAT_VALUES = %w(0 25 50 75 90 100).freeze

  # Note: The constants below are for clarity.  Don't just change them,
  # or trend lines will be recording different cutoffs.
  # See below for their meaning.
  REACTIVATION_PERIOD = 14 # number of days from reminder to update.
  ACTIVE_PERIOD = 30 # number of days; an active project entries has an update

  before_create :stamp

  # Stamp (fill in) the current values into a ProjectStat. Uses database.
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def stamp
    # Use a transaction to get values from a single consistent point in time.
    Project.transaction do
      # Count projects at different levels of completion
      STAT_VALUES.each do |completion|
        send "percent_ge_#{completion}=", Project.gteq(completion).count
      end

      # These use 1.day.ago, so a create or updates in 24 hours + fractional
      # seconds won't be counted today, and *might* not be counted previously.
      # This isn't important enough to solve.
      self.created_since_yesterday = Project.created_since(1.day.ago).count

      # Exclude newly-created records from updated_since count
      self.updated_since_yesterday = Project.updated_since(1.day.ago).count -
                                     created_since_yesterday

      # Record the number of reminders sent within the day.
      self.reminders_sent =
        Project.where('last_reminder_at > ?', 1.day.ago).count

      # If an inactive project becomes active within REACTIVATION_PERIOD
      # number of days after a reminder, the reminder is likely to be the
      # cause.  Record the number of such projects.
      self.reactivated_after_reminder =
        Project.where('last_reminder_at > ?', REACTIVATION_PERIOD.day.ago)
               .where('updated_at > ?', REACTIVATION_PERIOD.day.ago).count

      # Record the number of active project badge entries
      # (the number of project badge entries updated
      # within ACTIVE_PERIOD number of days)
      self.active_projects = Project.updated_since(ACTIVE_PERIOD.day.ago).count
      self.active_in_progress =
        Project.updated_since(ACTIVE_PERIOD.day.ago)
               .where('badge_percentage < 100').count
    end
    self # Return self to support method chaining
  end
  # rubocop:enable Metrics/AbcSize
end
