# frozen_string_literal: true

# JSON data doesn't depend on locale
json.cache! @project, expires_in: 10.minutes do
  json.partial! 'project', project: @project
end
