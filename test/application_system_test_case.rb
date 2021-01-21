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

# The chromedriver occasionally calls out with its own API,
# which isn't part of the system under test. This can occasionally
# cause an error of this form:
# An HTTP request has been made that VCR does not know how to handle:
# GET https://chromedriver.storage.googleapis.com/LATEST_RELEASE_87.0.4280
# The following code resolves it, see:
# https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock
# https://github.com/titusfortner/webdrivers/issues/109

require 'uri'

# With activesupport gem
driver_hosts =
  Webdrivers::Common.subclasses.map do |driver|
    URI(driver.base_url).host
  end

VCR.configure { |config| config.ignore_hosts(*driver_hosts) }
