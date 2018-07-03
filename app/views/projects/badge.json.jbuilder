# frozen_string_literal: true

# JSON data doesn't depend on locale
json.cache! ['badge-json', @project], expires_in: 10.minutes do
  json.id @project.id
  json.name @project.name
  json.updated_at @project.updated_at
  json.badge_level @project.badge_level
  json.tiered_percentage @project.tiered_percentage
end
