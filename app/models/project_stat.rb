# frozen_string_literal: true

class ProjectStat < ActiveRecord::Base
  # TODO: Remove created_at and updated_at default fields; we don't need them,
  # and "created_at" won't be *exactly* right because it will record the
  # creation time of the record, not when the statistics were captured.

  # Given a new (empty) project stat, fill it with current data.
  # rubocop:disable Metrics/AbcSize
  def stamp
    Project.transaction do
      self.when = DateTime.now.utc
      self.all = Project.count
      self.percent_ge_25 = Project.where('badge_percentage >= 25').count
      self.percent_ge_50 = Project.where('badge_percentage >= 50').count
      self.percent_ge_75 = Project.where('badge_percentage >= 75').count
      self.percent_ge_90 = Project.where('badge_percentage >= 90').count
      self.percent_ge_100 = Project.where('badge_percentage >= 100').count
    end
    self
  end

  # Record a new ProjectStat in the database; depends on stamp.
  def self.record
    ProjectStat.new.stamp.save
  end
end
