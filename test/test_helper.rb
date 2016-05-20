# frozen_string_literal: true
ENV['RAILS_ENV'] ||= 'test'

if ENV['CI']
  require 'minitest/retry'
  Minitest::Retry.use!
end

require 'simplecov'
SimpleCov.start 'rails' do
  add_group 'Validators', 'app/validators'
  add_filter '/config/'
  add_filter '/lib/tasks'
  add_filter '/test/'
  add_filter '/vendor/'
end

if ENV['CI']
  require 'codecov'
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Codecov
  ]
else
  SimpleCov.formatters = SimpleCov::Formatter::HTMLFormatter
end

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'webmock/minitest'
# This would disable network connections; would interfere with vcr:
WebMock.disable_net_connect!(allow_localhost: true)

# For more info on vcr, see https://github.com/vcr/vcr
# WARNING: Do *NOT* put the fixtures into test/fixtures (./fixtures is ok);
# Rails will try to automatically load them into models, resulting in
# confusing error messages.
require 'vcr'
VCR.configure do |config|
  config.ignore_localhost = true
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock
end

require 'minitest/rails/capybara'

driver = ENV['DRIVER'].try(:to_sym)

setup_poltergeist =
  lambda do
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, timeout: ENV['CI'] ? 30 : 60_000)
    end
  end

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, args: ['no-sandbox'])
end
if driver == :poltergeist
  require 'capybara/poltergeist'
  setup_poltergeist.call
  Capybara.default_driver = :poltergeist
  Capybara.current_driver = :poltergeist
  Capybara.javascript_driver = :poltergeist
elsif driver.nil?
  require 'capybara/poltergeist'
  setup_poltergeist.call
  Capybara.default_driver = :rack_test
  Capybara.current_driver = :rack_test
  Capybara.javascript_driver = :poltergeist
else
  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, browser: driver)
  end
  Capybara.default_driver = :selenium
  Capybara.current_driver = :selenium
  Capybara.javascript_driver = :selenium
end

Capybara.default_max_wait_time = 5
Capybara.server_port = 31_337

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical
    # order.
    ActiveRecord::Migration.maintain_test_schema!
    self.use_transactional_fixtures = true
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def configure_omniauth_mock
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:github, omniauth_hash)
    end

    def contents(file_name)
      IO.read "test/fixtures/files/#{file_name}"
    end

    # rubocop:disable Metrics/MethodLength
    def kill_sticky_headers
      # https://alisdair.mcdiarmid.org/kill-sticky-headers/
      script = <<-EOS
      (function () {
        var i, elements = document.querySelectorAll('body *');

        for (i = 0; i < elements.length; i++) {
          if (getComputedStyle(elements[i]).position === 'fixed') {
            elements[i].parentNode.removeChild(elements[i]);
          }
        }
      })();
      EOS
      execute_script script
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def log_in_as(
      user, password: 'password', provider: 'local', remember_me: '1',
      time_last_used: Time.now.utc
    )
      # This is based on "Ruby on Rails Tutorial" by Michael Hargle, chapter 8,
      # https://www.railstutorial.org/book
      if integration_test?
        post login_path,
             session: {
               email:  user.email, password: password,
               provider: provider, remember_me: remember_me,
               time_last_used: time_last_used
             }
        # Do this instead, it at least checks the password:
        # session[:user_id] = user.id if user.try(:authenticate, password)
      else
        session[:user_id] = user.id
        session[:time_last_used] = time_last_used
      end
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
          break if "#{uri.path}?#{uri.query}" == url
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

    def omniauth_hash
      {
        'provider' => 'github',
        'uid' => '12345',
        'credentials' => { 'token' => vcr_oauth_token },
        'info' => {
          'name' => 'CII Test',
          'email' => 'test@example.com',
          'nickname' => 'CIITheRobot'
        }
      }
    end

    def vcr_oauth_token
      y = YAML.load_file('test/vcr_cassettes/github_login.yml')
              .with_indifferent_access
      url = y[:http_interactions][1][:request][:uri]
      Addressable::URI.parse(url).query_values['access_token']
    end
  end
end
