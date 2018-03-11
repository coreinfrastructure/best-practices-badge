# frozen_string_literal: true

# copyright 2015-2017, the linux foundation, ida, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# class StaticPagesControllerTest < ActionController::TestCase
class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test 'should get home' do
    get root_path(locale: 'en')
    assert_response :success
    # assert_template 'home'
    # Check that it has some content
    assert_includes @response.body, 'Open Source Software'
    assert_includes @response.body, 'More information on the'
    assert_includes @response.body, 'target='
    # target=... better not end immediately, we need rel="noopener"
    refute_includes @response.body, 'target=[^ >]+>'
    # Ensure locale cross-references are present, and that
    # the home page URL doesn't have a trailing slash UNLESS there's no locale.
    # If there's no locale, include a '/' to be consistent with root_path.
    #
    # There's a weird test environment artifact I haven't been
    # able to track down.  The view response sometimes has an original url of
    # http://127.0.0.1:31337 and other times it's http://www.example.com.
    # Values such as "request.host" are consistently the second value.
    # This doesn't happen when we only test this file, but instead happens
    # when there's a full "rails test" - which means some other test
    # causes this.  It seems to be an artifact of the test environment, and
    # not actually a bug in the deployed code, so the test here will be
    # flexible to handle the variations that occur in the test environment.
    # See also: projects_controller_test.rb
    #
    assert_includes I18n.available_locales, :en
    assert_includes I18n.available_locales, :fr
    I18n.available_locales.each do |loc|
      # Metadata about related pages (useful for search engines)
      assert_match \
        %r{<link\ rel="alternate"\ hreflang="#{loc}"
         \ href="https?://[a-z0-9.:]+/#{loc}"\ />}x,
        @response.body
      # User locale selector (useful for users)
      assert_match \
        %r{<li><a\ href="https?://[a-z0-9.:]+/#{loc}">}x,
        @response.body
    end
    assert_match \
      %r{<link\ rel="alternate"\ hreflang="x-default"
       \ href="https?://[a-z0-9.:]+/"\ />}x,
      @response.body
  end

  test 'should get home in French when fr locale in URL' do
    get root_path(locale: :fr)
    assert_response :success
    # assert_template 'home'
    # Check that it has some content
    assert_includes @response.body, 'les projets de logiciel libre'
  end

  test 'should get cookie page' do
    get cookies_path(locale: :en)
    assert_response :success
    assert_includes @response.body, 'About Cookies'
    assert_includes @response.body, 'small data files'
  end

  test 'should get robots.txt' do
    get robots_path(locale: :en)
    assert_response :success
  end

  test 'should get criteria' do
    get criteria_path(locale: :en)
    assert_response :success

    get criteria_path(locale: :fr)
    assert_response :success

    get criteria_path(locale: :'zh-CN')
    assert_response :success
  end
end
