# frozen_string_literal: true

# Copyright the CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Must run headless and disable sandbox, see:
# https://medium.com/@john200Ok/running-rails-6-system-tests-using-chrome-headless-and-selenium-on-gitlab-ci-9b4de5cafcd0

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |option|
    option.add_argument('no-sandbox')
  end
end
