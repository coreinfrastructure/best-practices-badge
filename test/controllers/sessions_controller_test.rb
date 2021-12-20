# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user_melissa)
  end

  test 'should get new' do
    get '/en/sessions/new'
    assert_response :success

    # Do quick text search to see if email input field exists
    assert_match(
      /<input [^>]+ type="email" name="session\[email\]" id="session_email" /,
      @response.body
    )
    # Do a pickier check of the results using XPath selectors
    assert_select(
      'form/input[type="email"][name="session[email]"][id="session_email"]'
    )

    # Do quick text search for the password input field
    # We use parentheses here to make it clear "/" is a regex, not a division.
    assert_match(/<input [^>]+ type="password" /, @response.body)
    # Do a pickier check using XPath selectors
    assert_select(
      'form/input[type="password"]' \
      '[name="session[password]"][id="session_password"]'
    )

    # Ensure we have the link (button) for GitHub login.
    assert_select 'a[data-method="post"][href="/auth/github?locale=en"]'
  end

  test 'should redirect if already logged in' do
    log_in_as(@user, password: 'password1')
    get '/en/sessions/new'
    assert_response :redirect
    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_not flash.empty?
  end

  test 'Simple login (directly)' do
    # This is a trivial test; if this fails, more complicated tests will too.
    # We include this trivial test so we can separately see if
    # just the basics work.
    post '/en/login', params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password'
      }
    }
    assert_response :redirect
    assert_redirected_to root_url
    follow_redirect!
    assert flash && flash[:success]
    assert flash[:success].include?('Logged in!')
  end

  test 'local login fails if deny_login' do
    # WARNING: This test manipulates a global setting, namely
    # Rails.application.config.deny_login. Parallel testing with *processes*
    # is fine, parallel testing with *threads* will not work.
    old_deny = Rails.application.config.deny_login
    Rails.application.config.deny_login = true # Not thread-safe
    post '/en/login', params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password'
      }
    }
    assert flash && flash[:danger]
    assert flash[:danger].include?('logins temporarily disabled')
    assert '403', response.code
    Rails.application.config.deny_login = old_deny
  end
end
