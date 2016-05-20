# frozen_string_literal: true

class ProjectStat < ActiveRecord::Base
  STAT_VALUES = %w(0 25 50 75 90 100).freeze

  after_initialize :stamp

  # rubocop:disable Metrics/AbcSize
  def stamp
    # Count projects at different levels of completion
    Project.transaction do
      # binding.pry
      STAT_VALUES.each do |completion|
        send "percent_ge_#{completion}=", Project.gteq(completion).count
      end
      self.created_since_yesterday = Project.created_since(1.day.ago).count

      # Exclude newly-created records from updated_since count
      self.updated_since_yesterday = Project.updated_since(1.day.ago).count -
                                     Project.created_since(1.day.ago).count
    end
  end
  # rubocop:enable Metrics/AbcSize
end
