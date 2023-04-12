# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# *MUST* load 'simplecov' FIRST, before any other code is run.
# See: https://github.com/colszowka/simplecov/issues/296
require 'simplecov'

# *MUST* state VERY EARLY that we're in the test environment.
ENV['RAILS_ENV'] ||= 'test'

# Configure SimpleCov formatting before we start it
if ENV['CI']
  require 'codecov'
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Codecov
  ]
else
  SimpleCov.formatters = SimpleCov::Formatter::HTMLFormatter
end

# Start SimpleCov to track coverage
SimpleCov.start 'rails' do
  add_group 'Validators', 'app/validators'
  add_filter '/config/'
  add_filter '/lib/tasks'
  add_filter '/test/'
  add_filter '/vendor/'
end

# Some tests flap, producing false failures, so enable auto-retry
if ENV['CI']
  require 'minitest/retry'
  Minitest::Retry.use!
end

require 'minitest/reporters'
if ENV['CI'] || ENV['SLOW']
  Minitest::Reporters.use! [
    Minitest::Reporters::SpecReporter.new,
    Minitest::Reporters::MeanTimeReporter.new,
    Minitest::Reporters::HtmlReporter.new
  ]
else
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
end

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

# We must specially allow web calls by test drivers, e.g.,
# GET https://chromedriver.storage.googleapis.com/LATEST_RELEASE_75.0.3770
# See: https://github.com/titusfortner/webdrivers/issues/109
driver_urls = [
  %r{https://chromedriver.storage.googleapis.com/LATEST_RELEASE_[0-9.]+}
]

require 'webmock/minitest'
# This would disable network connections; would interfere with vcr:
WebMock.disable_net_connect!(allow_localhost: true, allow: driver_urls)

# For more info on vcr, see https://github.com/vcr/vcr
# WARNING: Do *NOT* put the fixtures into test/fixtures (./fixtures is ok);
# Rails will try to automatically load them into models, resulting in
# confusing error messages.
require 'vcr'
VCR.configure do |config|
  config.ignore_localhost = true
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock
  # Sometimes we have the "same" query but with and without per_page=...
  # query values.  Record both variants by recording new_episodes:
  config.default_cassette_options = { record: :new_episodes }
  # Default :match_requests_on => [:method, :uri]
  # You can also match on: scheme, port, method, host, path, query
  # You can create new matchers like this:
  # config.register_request_matcher :query_skip_changers do |r1, r2|
  #   URI(r1.uri).query == URI(r2.uri).query
  # end
  # config.match_on [:skip_changers]
  # Allow calls needed by test drivers
  # config.ignore_hosts(*driver_urls)
end

# The chromedriver occasionally calls out with its own API,
# which isn't part of the system under test. This can occasionally
# cause an error of this form:
# An HTTP request has been made that VCR does not know how to handle:
# GET https://chromedriver.storage.googleapis.com/LATEST_RELEASE_87.0.4280
# The following code resolves it, see:
# https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock
# https://github.com/titusfortner/webdrivers/issues/109

require 'webdrivers'
require 'uri'

# With activesupport gem
# driver_hosts =
# Webdrivers::Common.subclasses.map do |this_driver|
# URI(this_driver.base_url).host
# end

# VCR.configure { |config| config.ignore_hosts(*driver_hosts) }

# NOTE: We *could* speed up test execution by disabling PaperTrail
# except in cases where we check PaperTrail results. PaperTrail records all
# project creation and change events (enabling you to see older versions),
# so in some cases Papertrail slows tests slightly.  To do this, see:
# https://github.com/paper-trail-gem/paper_trail
# However, we have intentionally chosen to *not* do that.
# Where reasonable we have tried to keep the test environment
# the *same* as the production environment where it's reasonable to do so;
# every difference can hide a problem from our tests.
# The tests run fast enough as it is, and avoiding problems due to such
# differences is more important. At the least, we're making sure that
# PaperTrail doesn't cause a crash in the various tests, and that's worth
# checking.

module ActiveSupport
  # rubocop: disable Metrics/ClassLength
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical
    # order.
    ActiveRecord::Migration.maintain_test_schema!
    self.use_transactional_tests = true
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def configure_omniauth_mock(cassette = 'github_login')
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:github, omniauth_hash(cassette))
    end

    def contents(file_name)
      File.read "test/fixtures/files/#{file_name}"
    end

    # rubocop:disable Metrics/MethodLength
    def kill_sticky_headers
      # https://alisdair.mcdiarmid.org/kill-sticky-headers/
      script = <<-JAVASCRIPT_KILL_STICKY_HEADERS
      (function () {
        var i, elements = document.querySelectorAll('body *');

        for (i = 0; i < elements.length; i++) {
          if (getComputedStyle(elements[i]).position === 'fixed') {
            elements[i].parentNode.removeChild(elements[i]);
          }
        }
      })();
      JAVASCRIPT_KILL_STICKY_HEADERS
      execute_script script
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    # Note: In many tests we use "password" as the password.
    # Users can (no longer) create accounts with this too-easy password.
    # Using "password" helps test that users can log in to their
    # existing accounts, even if we make the password rules harsher later.
    def log_in_as(
      user,
      password: 'password',
      provider: 'local',
      remember_me: '1',
      make_old: false
    )
      # This is based on "Ruby on Rails Tutorial" by Michael Hargle, chapter 8,
      # https://www.railstutorial.org/book
      time_last_used = Time.now.utc
      post "#{login_path}#{'?make_old=true' if make_old}", params: {
        session: {
          email:  user.email, password: password,
          provider: provider, remember_me: remember_me,
          time_last_used: time_last_used
        }
      }
    end
    # rubocop:enable Metrics/MethodLength

    def scroll_to_see(id)
      # From http://toolsqa.com/selenium-webdriver/scroll-element-view-selenium-javascript/
      execute_script("document.getElementById('#{id}').scrollIntoView(false);")
    end

    def user_logged_in?
      # Returns true if a test user is logged in.
      !session[:user_id].nil?
    end

    def wait_for_jquery
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop until finished_all_jquery_requests?
      end
    end

    def wait_for_url(url)
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop do
          uri = URI.parse(current_url)
          break if url == "#{uri.path}?#{uri.query}"
        end
      end
    end

    private

    def finished_all_jquery_requests?
      evaluate_script('jQuery.active').zero?
    end

    def integration_test?
      # Returns true inside an integration test.
      # Based on "Ruby on Rails Tutorial" by Michael Hargle, chapter 8,
      # https://www.railstutorial.org/book
      defined?(post_via_redirect)
    end

    def omniauth_hash(cassette)
      {
        'provider' => 'github',
        'uid' => '12345',
        'credentials' => { 'token' => vcr_oauth_token(cassette) },
        'info' => {
          'name' => 'CII Test',
          'email' => 'test@example.com',
          'nickname' => 'bestpracticestest'
        }
      }
    end

    def vcr_oauth_token(cassette)
      github_login_vcr_file = "test/vcr_cassettes/#{cassette}.yml"
      return unless File.exist?(github_login_vcr_file)

      y = YAML.load_file(github_login_vcr_file).with_indifferent_access
      query_string = y[:http_interactions][0][:response][:body][:string]
      Rack::Utils.parse_nested_query(query_string)['access_token']
    end

    def key_with_nil_value(hash)
      hash.each do |k, v|
        return k.to_s if v.nil?
        next unless v.is_a?(Hash)

        nil_key = key_with_nil_value(v)
        next if nil_key == ''

        return "#{k}.#{nil_key}"
      end
      ''
    end

    # Re-implement assert_select - return true iff a CSS selection
    # using *selector* contains exactly "contents".
    # The problem is that assert_select fails oddly when running a global
    # "rails test" (though it works fine if running "rails test FILENAME").
    # To solve this, we re-implement assert_select so we have a working version.
    def my_assert_select(selector, contents)
      results = css_select(selector)
      results.each do |selection|
        return true if selection.content == contents
      end
      false
    end
  end
  # rubocop: enable Metrics/ClassLength
end
