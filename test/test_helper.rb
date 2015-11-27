ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start 'rails' do
  add_group 'Validators', 'app/validators'
  add_filter '/config/'
  add_filter '/lib/tasks'
  add_filter '/test/'
  add_filter '/vendor/'
end

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'webmock/minitest'
# This would disable network connections; would interfere with vcr:
# WebMock.disable_net_connect!(allow_localhost: true)

# For more info on vcr, see https://github.com/vcr/vcr
# WARNING: Do *NOT* put the fixtures into test/fixtures (./fixtures is ok);
# Rails will try to automatically load them into models, resulting in
# confusing error messages.
require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock # or :fakeweb
end

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical
    # order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Returns true if a test user is logged in.
    def logged_in?
      !session[:user_id].nil?
    end

    # Log in a test user.
    # TODO: Put 'provider' into the session, along with email and password
    # This is based on "Ruby on Rails Tutorial" by Michael Hargle, chapter 8,
    # https://www.railstutorial.org/book
    def log_in_as(user, options = {})
      password = options[:password] || 'password'
      provider = options[:provider] || 'local'
      if integration_test?
        post login_path,
             provider: provider,
             session: { email:  user.email, password: password }
        # Do this instead, it at least checks the password:
        # session[:user_id] = user.id if user.try(:authenticate, password)
      else
        session[:user_id] = user.id
      end
    end

    private

    # Returns true inside an integration test.
    # Based on "Ruby on Rails Tutorial" by Michael Hargle, chapter 8,
    # https://www.railstutorial.org/book
    def integration_test?
      defined?(post_via_redirect)
    end
  end
end
