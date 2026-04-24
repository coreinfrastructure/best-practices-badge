# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
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

  test 'local login with return_to redirects to destination' do
    destination = '/en/projects/1/passing/edit'
    post '/en/login', params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password',
        return_to: destination
      }
    }
    assert_response :redirect
    assert_redirected_to destination
  end

  test 'local login with protocol-relative return_to is rejected' do
    post '/en/login', params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password',
        return_to: '//evil.example.org/steal'
      }
    }
    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'local login with non-path return_to is rejected' do
    post '/en/login', params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password',
        return_to: 'javascript:alert(1)'
      }
    }
    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'local login with return_to of /en/login is rejected (loop prevention)' do
    post '/en/login', params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password',
        return_to: '/en/login'
      }
    }
    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'local login with return_to of /en/login/ is rejected' do
    post '/en/login', params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password',
        return_to: '/en/login/'
      }
    }
    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'local login with return_to of /en/login?x is rejected' do
    post '/en/login', params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password',
        return_to: '/en/login?x=1'
      }
    }
    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'login page with return_to includes it in github auth link and form' do
    destination = '/en/projects/1/passing/edit'
    get '/en/login', params: { return_to: destination }
    assert_response :success
    encoded = ERB::Util.url_encode(destination)
    assert_select "a[data-method='post'][href='/auth/github?locale=en&return_to=#{encoded}']"
    assert_select "input[type='hidden'][name='session[return_to]'][value='#{destination}']"
  end

  test 'local login fails if deny_login' do
    # WARNING: This test manipulates a global setting, namely
    # Rails.application.config.deny_login. Parallel testing with *processes*
    # is fine, parallel testing with *threads* will not work.
    old_deny = Rails.application.config.deny_login
    Rails.application.config.deny_login = true # Not thread-safe
    begin
      post '/en/login', params: {
        session: {
          provider: 'local', email: 'test@example.org', password: 'password'
        }
      }
      assert flash && flash[:danger]
      assert flash[:danger].include?('logins temporarily disabled')
      assert '403', response.code
    ensure
      Rails.application.config.deny_login = old_deny
    end
  end
end
# rubocop:enable Metrics/ClassLength
