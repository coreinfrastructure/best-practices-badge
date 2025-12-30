# frozen_string_literal: true

# Show project in JSON format.
# This is a partial so "show" and "index" can share this.
# Start with project attributes
transformed_attrs = project.attributes.dup

# Phase 2: Convert status fields from integers to strings for API compatibility
# During migration, some values may be integers, some may be stringified integers
Project::ALL_CRITERIA_STATUS.each do |status_field|
  status_value = transformed_attrs[status_field.to_s]
  if status_value.is_a?(Integer)
    transformed_attrs[status_field.to_s] = CriterionStatus::STATUS_VALUES[status_value]
  elsif status_value.is_a?(String) && status_value.match?(/\A[0-3]\z/)
    # Stringified integer from VARCHAR storage
    transformed_attrs[status_field.to_s] = CriterionStatus::STATUS_VALUES[status_value.to_i]
  end
  # If it's already a string name ('Met', etc.), leave it as-is
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
