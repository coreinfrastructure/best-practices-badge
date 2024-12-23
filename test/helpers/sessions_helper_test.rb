# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
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

  # Someday re-add a test for deny_login. This older test modifies global variables
  # and thus does not parallelize well.
  # test 'current_user returns nil when deny_login' do
  #   # First, log in as user
  #   # log_in_as(@user)
  #   # assert current_user == @user
  #   # # Previous login irrelevant once deny_login is true
  #   # deny_login_old = Rails.application.config.deny_login
  #   # Rails.application.config.deny_login = true
  #   # assert current_user.nil?
  #   # # Restore normal setting
  #   # Rails.application.config.deny_login = deny_login_old
  # end

  # Unit test.  There are tricky cases, so try various forms
  test 'check force_locale_url' do
    assert_equal 'https://a.b.c/', force_locale_url('https://a.b.c/', nil)
    assert_equal 'https://a.b.c/', force_locale_url('https://a.b.c', nil)
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
  class StubOctokitResult
    attr_accessor :permissions

    def initialize(admin, push, pull)
      self.permissions = { admin: admin, push: push, pull: pull }
    end
  end

  class StubOctokitClient
    def initialize(**params); end

    def repo(path, **_opts)
      if path == 'ciitest/asdf'
        StubOctokitResult.new(true, true, true)
      elsif path == 'ciitest2/asdf'
        StubOctokitResult.new(false, true, true)
      elsif path == 'ciitest3/asdf'
        StubOctokitResult.new(false, false, true)
      else
        raise Octokit::NotFound
      end
    end
  end

  # Unit test 'github_user_projects_include?'.
  # Doing integration tests with "real" data is a little dangerous
  # because that requires a user with a *lot* of repos; our test user
  # doesn't have that many, and we don't want to use real users for testing.
  # So we'll stub things out just enough to do a unit test.
  test 'unit test of github_user_projects_include?' do
    assert github_user_can_push?(
      'https://github.com/ciitest/asdf', StubOctokitClient
    )
    assert github_user_can_push?(
      'https://github.com/ciitest2/asdf', StubOctokitClient
    )
    assert_not github_user_can_push?(
      'https://github.com/ciitest3/asdf', StubOctokitClient
    )
    assert_not github_user_can_push?(
      'https://github.com/not-here/not-found',
      StubOctokitClient
    )
  end

  test 'unit test of get_gethub_owner' do
    assert_equal 'ciitest', get_github_owner('https://github.com/ciitest/1234')
    assert_equal 'asdf-123',
                 get_github_owner('https://github.com/asdf-123/456')
    assert_equal 'ciitest2',
                 get_github_owner('https://github.com/ciitest2/1234')
    assert_nil get_github_owner('http://githubs.com/asdf/1234')
  end

  test 'unit test of get_github_path' do
    assert_equal 'ciitest/1234',
                 get_github_path('https://github.com/ciitest/1234')
    assert_equal 'asdf-123/456',
                 get_github_path('https://github.com/asdf-123/456')
    assert_equal 'ciitest2/1234',
                 get_github_path('https://github.com/ciitest2/1234')
    assert_nil get_github_path('http://githubs.com/asdf/1234')
  end

  test 'unit test of valid_github_url' do
    assert valid_github_url? 'https://github.com/asdf/1234/'
    assert valid_github_url? 'https://github.com/asdf-123_/1234as-/'
    assert_not valid_github_url? 'https://github.com/asdf123_/1234%20as-/'
    assert_not valid_github_url? 'https://github.com/asdf%20123_/1234as-/'
    assert_not valid_github_url? 'https://github.com/asdf123_/1234 as-/'
    assert_not valid_github_url? 'https://github.com/asdf 123_/1234as-/'
    assert_not valid_github_url? 'https://github.com.more/asdf-123_/1234as-/'
    assert_not valid_github_url? 'https://my.github.com/asdf-123_/1234as-/'
    assert_not valid_github_url? 'http://github.com/asdf/1234/'
    assert_not valid_github_url? 'https://github.com/asdf/1234-/s'
    assert_not valid_github_url? 'https://github.com/asdf/1234/?'
    assert_not valid_github_url? 'https://githubs.com/asdf/1234/'
  end
end
# rubocop: enable Metrics/BlockLength
