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
    # WARNING: this DOES NOT attempt to do a "post" during integration test
    # to create a session. Thus, it doesn't receive the expected redirection
    # and resulting page.  Instead, it just sets the session value for the
    # current user if the password is correct.  The problem is that even
    # with a correct password, a 'post' ALWAYS returned the
    # 'failed login' page with a reply code of 200,
    # instead of correctly replying with a redirect on successful login.
    # That's because although "post"  correctly invokes the method
    # SessionController#create, create is NOT receiving the
    # email, password, or provider.  # Instead, create gets this:
    # (byebug) params[:provider]
    #   nil
    # (byebug) params[:session]
    #   {"email"=>"", "password"=>""}
    # This is based on "Ruby on Rails Tutorial" by Michael Hargle, chapter 8,
    # https://www.railstutorial.org/book
    def log_in_as(user, options = {})
      password = options[:password] || 'password'
      provider = options[:provider] || 'local'
      if integration_test?
        # post login_path, session: { email:       user.email,
        #                            password:    password,
        #                            remember_me: remember_me }
        # Do this instead, it at least checks the password:
        if !user.try(:authenticate, password)
          session[:user_id] = user.id
        end
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
