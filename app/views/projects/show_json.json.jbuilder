# frozen_string_literal: true

# JSON data doesn't depend on locale.

# The JSON data *does* depend on the additional_rights value.
# However, it is very rare for additional_rights to change, so we'll just
# depend on the expiration time to invalidate old data, and for a short time
# we'll return an obsolete additional_rights list.
# If it's important to *immediately* return the current list,
# then we could invalidate the cache value on a change to additional_rights,
# or we could instead add this to the cache key:
# additional_rights_list = project.additional_rights.pluck(:user_id).join(',')

json.cache! @project, expires_in: 10.minutes do
  json.partial! 'project', project: @project
end
