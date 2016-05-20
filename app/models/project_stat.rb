# frozen_string_literal: true

class ProjectStat < ActiveRecord::Base
  STAT_VALUES = %w(0 25 50 75 90 100).freeze

  after_initialize :stamp

  def stamp
    # Count projects at different levels of completion
    Project.transaction do
      # binding.pry
      STAT_VALUES.each do |completion|
        send "percent_ge_#{completion}=", Project.gteq(completion).count
      end
    end
  end
end
