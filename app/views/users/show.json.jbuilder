# frozen_string_literal: true

# Show specific approved user attributes.
# We use JSON to help implement the EU General Data Protection Regulation
# (GDPR) "Data portability" requirements; JSON is a standard format.
# We do not use "json.merge! @user.attributes" because there are many
# irrelevant fields, and we especially want to restrict access to some.
json.call(
  @user, :id, :name, :nickname, :uid, :provider, :created_at, :updated_at
)
# This is an array of the project ids this user owns.
json.projects @user.projects.pluck(:id)
# Generate { project1.id: ['edit'], project2.id: ['edit'], ...}.
# We generate this format in case there's more than 1 right in the future.
# We could use @user.additional_rights.pluck(:id) instead, but we've
# already calculated it so there's no point in doing it twice.
json.additional_rights(
  @projects_additional_rights.pluck(:id).each_with_object({}) do |p, result|
    result[p] = ['edit']
  end
)
#
# current user or admin can see more
# Do NOT cache this server-side, since this includes the email address
if @user == current_user || current_user&.admin?
  json.preferred_locale @user.preferred_locale
  json.email @user.email_if_decryptable
  json.call(@user, :activated, :activated_at, :reset_sent_at)
  json.call(@user, :last_login_at)
  json.call(@user, :use_gravatar)
end
