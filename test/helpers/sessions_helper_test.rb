# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

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

  # Unit test.  There are tricky cases, so try various forms
  test 'check force_locale_url' do
    assert_equal 'https://a.b.c/fr/', force_locale_url('https://a.b.c/', :fr)
    assert_equal 'https://a.b.c/fr/', force_locale_url('https://a.b.c', :fr)
    assert_equal 'https://a.b.c/',
                 force_locale_url('https://a.b.c?locale=fr', :en)
    assert_equal 'https://a.b.c/',
                 force_locale_url('https://a.b.c?locale=en', :en)
    assert_equal 'https://a.b/', force_locale_url('https://a.b', :en)
    assert_equal 'https://a.b/fr/projects',
                 force_locale_url('https://a.b/zh-CN/projects', :fr)
    assert_equal 'https://a.b/zh-CN/projects',
                 force_locale_url('https://a.b/fr/projects', :'zh-CN')
    assert_equal 'https://a.b/zh-CN/projects',
                 force_locale_url('https://a.b/projects', :'zh-CN')
    assert_equal 'https://a.b/projects',
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
end
