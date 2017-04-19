# frozen_string_literal: true

json.array!(@users) do |user|
  json.call(user, :id, :name) # Add :provider, :nickname ?
  # json.url users_url(user, format: :json)
end
