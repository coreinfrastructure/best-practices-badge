# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop: disable Metrics/BlockLength
class SessionsHelperTest < ActionView::TestCase
  setup do
    @user = users(:test_user)
    remember(@user)
  end

  test 'current_user returns right user when session is nil' do
    assert_equal @user, current_user
    assert_not session[:time_last_used].nil?
    assert user_logged_in?
  end

  test 'current_user returns nil when remember digest is wrong' do
    @user.update_attribute(:remember_digest, User.digest(User.new_token))
    assert_nil current_user
  end

  test 'current_user returns nil when deny_login' do
    # First, log in as user
    log_in_as(@user)
    assert current_user == @user
    # Previous login irrelevant once deny_login is true
    deny_login_old = Rails.application.config.deny_login
    Rails.application.config.deny_login = true
    assert current_user.nil?
    # Restore normal setting
    Rails.application.config.deny_login = deny_login_old
  end

  # Unit test.  There are tricky cases, so try various forms
  test 'check force_locale_url' do
    assert_equal 'https://a.b.c/',
                 force_locale_url('https://a.b.c/', nil)
    assert_equal 'https://a.b.c/',
                 force_locale_url('https://a.b.c', nil)
    assert_equal 'https://a.b.c/fr', force_locale_url('https://a.b.c/', :fr)
    assert_equal 'https://a.b.c/fr', force_locale_url('https://a.b.c', :fr)
    assert_equal 'https://a.b.c/en',
                 force_locale_url('https://a.b.c?locale=fr', :en)
    assert_equal 'https://a.b.c/en',
                 force_locale_url('https://a.b.c?locale=en', :en)
    assert_equal 'https://a.b/en', force_locale_url('https://a.b', :en)
    assert_equal 'https://a.b/fr/projects',
                 force_locale_url('https://a.b/zh-CN/projects', :fr)
    assert_equal 'https://a.b/zh-CN/projects',
                 force_locale_url('https://a.b/fr/projects', :'zh-CN')
    assert_equal 'https://a.b/zh-CN/projects',
                 force_locale_url('https://a.b/projects', :'zh-CN')
    assert_equal 'https://a.b/en/projects',
                 force_locale_url('https://a.b/zh-CN/projects', :en)
    assert_equal 'https://a.b/fr/projects/1?criteria_level=2',
                 force_locale_url(
                   'https://a.b/projects/1?locale=ja&criteria_level=2', :fr
                 )
    assert_equal 'https://a.b/fr/projects/1?criteria_level=2',
                 force_locale_url(
                   'https://a.b/projects/1?criteria_level=2&locale=ja', :fr
                 )
  end

  # Test stub for testing github_user_projects_include?
  class StubOctokitError < StandardError
  end
  # rubocop: disable Metrics/MethodLength
  class StubOctokitClient
    def initialize(**params); end

    def auto_paginate=(value); end

    def repos(_user = nil, **opts)
      page = opts.fetch(:page, 1)
      if page == 1
        [
          { id: 100, html_url: 'https://github.com/ciitest/junk' },
          { id: 101, html_url: 'https://github.com/ciitest/foo' }
        ]
      elsif page == 2
        [{ id: 105, html_url: 'https://github.com/ciitest/stuff' }]
      elsif page == 3
        []
      else
        raise StubOctokitError
      end
    end
  end
  # rubocop: enable Metrics/MethodLength

  # Unit test 'github_user_projects_include?'.
  # Doing integration tests with "real" data is a little dangerous
  # because that requires a user with a *lot* of repos; our test user
  # doesn't have that many, and we don't want to use real users for testing.
  # So we'll stub things out just enough to do a unit test.
  test 'unit test of github_user_projects_include?' do
    assert github_user_projects_include?(
      'https://github.com/ciitest/stuff',
      StubOctokitClient
    )
    assert !github_user_projects_include?(
      'https://github.com/not-here/not-found',
      StubOctokitClient
    )
  end
end
# rubocop: enable Metrics/BlockLength
