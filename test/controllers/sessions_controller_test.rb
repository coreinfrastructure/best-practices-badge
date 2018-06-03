# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  setup do
    @user = users(:test_user_melissa)
  end

  test 'should get new' do
    get :new, params: { locale: :en }
    assert_response :success
  end

  test 'should redirect logged in' do
    log_in_as(@user)
    get :new, params: { locale: :en }
    assert_not flash.empty?
    assert_redirected_to root_url
  end

  test 'login via session controller' do
    post :create, params: {
      session: {
        provider: 'local', email: 'test@example.org', password: 'password'
      }
    }
    assert flash && flash[:success]
    assert flash[:success].include?('Logged in!')
  end

  test 'login via session controller fails if' do
    old_deny = Rails.application.config.deny_login
    Rails.application.config.deny_login = true # Not thread-safe
    post :create, params: {
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
