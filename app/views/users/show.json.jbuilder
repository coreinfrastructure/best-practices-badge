# frozen_string_literal: true

# Only show specific approved user attributes
# json.merge! @user.attributes
json.call(
  @user, :id, :name, :nickname, :uid, :provider, :created_at, :updated_at
)
# ONLY show email to admins
json.email user.email if current_user&.admin?
