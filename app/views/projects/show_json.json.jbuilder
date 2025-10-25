# frozen_string_literal: true

# JSON data doesn't depend on locale.

# The JSON data *does* depend on the additional_rights value.
# Cache is automatically invalidated when additional_rights change,
# because AdditionalRight belongs_to :project with touch: true, which
# updates project.updated_at and invalidates the cache key.

json.cache! @project, expires_in: 10.minutes do
  json.partial! 'project', project: @project
end
