# frozen_string_literal: true

# Show project in JSON format.
# This is a partial so "show" and "index" can share this.
# Start with project attributes
transformed_attrs = project.attributes.dup

# Convert status fields from integers to strings for API compatibility
# Database stores integers (0=?, 1=Unmet, 2=N/A, 3=Met), API returns strings
# Also handles pre-migration strings gracefully (defensive programming)
Project::ALL_CRITERIA_STATUS.each do |status_field|
  status_value = transformed_attrs[status_field.to_s]
  next if status_value.nil?
  next if status_value.is_a?(String) # Already a string (pre-migration data)

  transformed_attrs[status_field.to_s] = CriterionStatus::STATUS_VALUES[status_value]
end

# Convert baseline field names to display form (uppercase with dashes)
# Uses precomputed mapping for performance (O(1) lookup, no allocations)
transformed_attrs = transformed_attrs.transform_keys do |key|
  ProjectsHelper::BASELINE_FIELD_DISPLAY_NAME_MAP.fetch(key, key)
end

json.merge! transformed_attrs
json.badge_level project.badge_level
json.additional_rights project.additional_rights.pluck(:user_id)

# rubocop:disable Rails/OutputSafety
json.project_entry_attribution('Please credit '.html_safe +
                               project.user.name +
                               ' and the CII Best Practices badge' \
                               ' contributors.')
# rubocop:enable Rails/OutputSafety
if project.show_entry_license?
  json.project_entry_license 'CC-BY-3.0+'
else
  json.project_entry_license 'CC-BY-3.0'
end
