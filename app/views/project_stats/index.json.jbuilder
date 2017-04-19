# frozen_string_literal: true

json.array!(@project_stats) do |project_stat|
  # rubocop:disable Metrics/LineLength
  json.extract! project_stat, :id, :percent_ge_0, :percent_ge_25, :percent_ge_50, :percent_ge_75, :percent_ge_90, :percent_ge_100, :created_since_yesterday, :updated_since_yesterday, :created_at, :updated_at, :reminders_sent, :reactivated_after_reminder, :active_projects, :active_in_progress, :projects_edited, :active_edited_projects, :active_edited_in_progress
  # rubocop:enable Metrics/LineLength
  json.url project_stat_url(project_stat, format: :json)
end
