# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class ProjectGetTest < ActionDispatch::IntegrationTest
  setup do
    # @user = users(:test_user)
    @project_one = projects(:one)
  end

  # rubocop:disable Metrics/BlockLength
  test 'ensure getting project has expected values (esp. security headers)' do
    # Check project page values, primarily the various hardening headers
    # (in particular the Content Security Policy (CSP) header).
    # We want to make sure these headers maximally limit what browsers will
    # do as an important hardening measure.
    # The "projects" page is the page most at risk of malicious data
    # from untrusted users, so we specifically test
    # the headers for this most-at-risk page.
    # We have to do this as an integration test, not as a controller test,
    # because the secure_headers gem integrates at the Rack level
    # (thus a controller test does not invoke it).

    get project_path(id: @project_one.id, locale: 'en')
    assert_response :success

    # Check some normal headers
    assert_equal('text/html; charset=utf-8', @response.headers['Content-Type'])
    assert_equal(
      'max-age=0, private, must-revalidate',
      @response.headers['Cache-Control']
    )

    # Check hardening headers
    assert_equal(
      "default-src 'self'; base-uri 'self'; block-all-mixed-content; " \
      "form-action 'self'; frame-ancestors 'none'; " \
      "img-src 'self' secure.gravatar.com avatars.githubusercontent.com; " \
      "object-src 'none'; script-src 'self'; style-src 'self'",
      @response.headers['Content-Security-Policy']
    )
    assert_equal(
      'no-referrer-when-downgrade',
      @response.headers['Referrer-Policy']
    )
    assert_equal('nosniff', @response.headers['X-Content-Type-Options'])
    assert_equal('DENY', @response.headers['X-Frame-Options'])
    assert_equal(
      'none',
      @response.headers['X-Permitted-Cross-Domain-Policies']
    )
    assert_equal('1; mode=block', @response.headers['X-XSS-Protection'])
    # Check warning on development system
    assert_match 'This is not the production system', response.body

    # We did NOT send an origin, so we don't send CORS headers
    # such as 'Access-Control-Allow-Origin'; check that.
    # If we send CORS headers "no matter what", change this, but be sure
    # that the CORS header values are secure.
    assert_nil(@response.headers['Access-Control-Allow-Origin'])
    assert_nil(@response.headers['Access-Control-Allow-Methods'])
    assert_nil(@response.headers['Access-Control-Allow-Credentials'])
  end
  # rubocop:enable Metrics/BlockLength

  test 'ensure CORS set when origin set' do
    get project_path(@project_one, locale: :en),
        headers: { 'Origin' => 'https://en/example.com' }
    assert_response :success

    # When there's an origin, we allow just GET from anywhere.
    assert_equal('*', @response.headers['Access-Control-Allow-Origin'])
    assert_equal(
      'GET, OPTIONS',
      @response.headers['Access-Control-Allow-Methods']
    )

    # It would be a security disaster if this was true, so let's make
    # sure it isn't true.  This test just ensures it's blank.
    # It would also be okay if this was false, but our code doesn't do that.
    assert_nil(@response.headers['Access-Control-Allow-Credentials'])

    # It could be a security disaster if caches always served the same data
    # to different CORS origins, because private information (e.g., to system
    # admins) might leak in a cache.  The "rack-cors" gem already handles
    # this by inserting "Vary: Origin", as is standard recommended behavior
    # when using CORS.  However, it's important for security, so let's
    # verify that caching varies depending on the Origin.
    assert_equal('Accept-Encoding, Origin', @response.headers['Vary'])
  end

  test 'Redirect malformed query string criteria_level,2' do
    get project_path(id: @project_one.id, locale: 'en') + '?criteria_level,2'
    # Should redirect
    assert_response 301
    assert_redirected_to project_path(
      id: @project_one.id, locale: 'en', criteria_level: 2
    )
  end

  test 'Redirect malformed query string criteria_level,1' do
    get project_path(id: @project_one.id, locale: 'de') + '?criteria_level,1'
    # Should redirect
    assert_response 301
    assert_redirected_to project_path(
      id: @project_one.id, locale: 'de', criteria_level: 1
    )
  end

  test 'Redirect malformed query string criteria_level,0' do
    get project_path(id: @project_one.id, locale: 'fr') + '?criteria_level,0'
    # Should redirect
    assert_response 301
    assert_redirected_to project_path(
      id: @project_one.id, locale: 'fr', criteria_level: 0
    )
  end
end
