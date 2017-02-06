# Only show specific approved user attributes
# json.merge! @user.attributes
json.(@user, :id, :name) # add :provider, :nickname ?
