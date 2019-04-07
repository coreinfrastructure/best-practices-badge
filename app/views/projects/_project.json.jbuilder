# frozen_string_literal: true

# Show project in JSON format.
# This is a partial so "show" and "index" can share this.
json.merge! project.attributes
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
