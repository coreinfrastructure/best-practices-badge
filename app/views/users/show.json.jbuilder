# frozen_string_literal: true

# Only show specific approved user attributes
# json.merge! @user.attributes
json.call(@user, :id, :name) # add :provider, :nickname ?
