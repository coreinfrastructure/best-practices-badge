json.array!(@users) do |user|
  json.(user, :id, :name) # Add :provider, :nickname ?
  # json.url users_url(user, format: :json)
end
