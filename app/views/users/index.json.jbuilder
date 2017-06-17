# frozen_string_literal: true

json.array!(@users) do |user|
  json.call(
    user, :id, :name, :id, :name, :nickname, :uid, :provider,
    :created_at, :updated_at
  )
  # ONLY show email to admins
  json.email user.email if current_user&.admin?
  # json.url users_url(user, format: :json)
end
