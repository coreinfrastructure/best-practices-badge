# frozen_string_literal: true

require 'capybara/minitest'
require 'capybara/rails'
require 'selenium/webdriver'
# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'webdrivers'

# Set up a test environment to run client-side JavaScript.
# Setup Capybara -> selenium -> webdriver -> headless chrome/chromium. See:
# https://robots.thoughtbot.com/headless-feature-specs-with-chrome

# Register "headless_chrome" driver - use it via Selenium.
# The configuration approach documented here isn't actually headless:
# https://robots.thoughtbot.com/headless-feature-specs-with-chrome
# So we instead use the approach documented in:
# https://github.com/teamcapybara/capybara/blob/master/spec/
# selenium_spec_chrome.rb#L6
Capybara.register_driver :headless_chrome do |app|
  browser_options = Selenium::WebDriver::Chrome::Options.new
  browser_options.binary = ENV.fetch('GOOGLE_CHROME_SHIM', nil) if ENV['CI']
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu' if Gem.win_platform?
  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
  driver.browser.download_path = Capybara.save_path
  driver
end

# Register "chrome" driver - use it via Selenium.
Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

# Note that DRIVER only controls the Capybara javascript_driver.
driver = ENV['DRIVER'].try(:to_sym)
Capybara.javascript_driver = driver.present? ? driver : :headless_chrome

Capybara.default_max_wait_time = 5
Capybara.server_port = 31_337

# By default newer versions of Capybara have the annoying habit of
# sending this in the middle of a test:
# > Capybara starting Puma...
# > * Version 3.12.2 , codename: Llamas in Pajamas
# > * Min threads: 0, max threads: 4
# > * Listening on tcp://127.0.0.1:31337
# This makes it hard to see the test status, so quiet it per:
# Capybara.server = :puma, { Silent: true }
# NOTE: This forces Capybara's server to be Puma; if the production server
# is something else, you might want to change this. For more info, see:
# https://github.com/rails/rails/issues/28109
# https://github.com/rspec/rspec-rails/issues/1897
Capybara.server = :puma, { Silent: true }

# Must run headless and disable sandbox, see:
# https://medium.com/@john200Ok/running-rails-6-system-tests-using-chrome-headless-and-selenium-on-gitlab-ci-9b4de5cafcd0

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |option|
    option.add_argument('no-sandbox')
  end
end
