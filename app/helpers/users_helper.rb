# frozen_string_literal: true
module UsersHelper
  # Returns avatar image tag for the given user.
  def avatar_for(user)
    image_tag(user.avatar_url, alt: user.name, class: 'avatar')
  end
end
