ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start
require 'coveralls'
Coveralls.wear!

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

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

    # Logs in a test user.
    def log_in_as(user, options = {})
      password = options[:password] || 'password'
      if integration_test?
        post login_path, session: { email:       user.email,
                                    password:    password,
                                    remember_me: remember_me }
      else
        session[:user_id] = user.id
      end
    end

    private

    # Returns true inside an integration test.
    def integration_test?
      defined?(post_via_redirect)
    end
  end
end
