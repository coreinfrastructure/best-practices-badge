# frozen_string_literal: true

class ProjectStat < ActiveRecord::Base
  STAT_VALUES = %w(0 25 50 75 90 100).freeze

  before_create :stamp

  # Stamp (fill in) the current values into a ProjectStat. Uses database.
  # rubocop:disable Metrics/AbcSize
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
    end
    self # Return self to support method chaining
  end
  # rubocop:enable Metrics/AbcSize
end
