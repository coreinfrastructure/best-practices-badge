# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

module UsersHelper
  # Returns avatar image tag for the given user.
  def avatar_for(user)
    image_tag(user.avatar_url, alt: user.name, class: 'avatar', size: '80x80')
  end
end
