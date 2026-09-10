# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Tests PendingResubmissionsController#show (docs/login-session-implementation.md
# section 15): stashed-submission lookup is keyed only by
# session[:pending_resubmission_id], never by anything in params.
class PendingResubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @user = users(:test_user) # local user, owns @project
  end

  # Triggers the real stash path (a logged-out PATCH to a project edit
  # action) rather than constructing a PendingResubmission by hand, so this
  # exercises the actual session[:pending_resubmission_id] write too.
  def stash_a_pending_resubmission(new_name: 'Stashed name')
    patch "/en/projects/#{@project.id}", params: {
      project: { name: new_name }
    }
    PendingResubmission.last
  end

  test 'no pending resubmission in session shows expired message' do
    # Hardcode the locale prefix: this is the test's very first request, so
    # there is no prior @controller for the pending_resubmission_path route
    # helper to infer a locale from, and an unprefixed path would redirect
    # once via redir_missing_locale before ever reaching #show, an extra
    # hop on top of the one this test means to check.
    get '/en/pending_resubmissions'
    assert_response :redirect
    follow_redirect!
    assert_includes @response.body, 'may have expired'
  end

  test 'shows stashed fields and resubmit button after a stash' do
    pending = stash_a_pending_resubmission(new_name: 'Resubmit me')
    get pending_resubmission_path
    assert_response :success
    assert_select "input[type='hidden'][name='project[name]'][value='Resubmit me']"
    assert_select "form[action='#{pending.resubmit_path}']"
  end

  test 'is single-use: a second visit finds nothing' do
    stash_a_pending_resubmission
    get pending_resubmission_path
    assert_response :success

    get pending_resubmission_path
    assert_response :redirect
    follow_redirect!
    assert_includes @response.body, 'may have expired'
  end

  test 'destroys the row on the first visit regardless of outcome' do
    pending = stash_a_pending_resubmission
    get pending_resubmission_path
    assert_not PendingResubmission.exists?(pending.id)
  end

  test 'shows sensitive-fields-dropped warning when email/password were stripped' do
    patch "/en/users/#{@user.id}", params: {
      user: { name: @user.name, email: @user.email }
    }
    get pending_resubmission_path
    assert_response :success
    # Not "couldn't": t() output is HTML-escaped by ERB, so the rendered
    # apostrophe is "&#39;", not "'". Assert on a stretch of the message
    # without one.
    assert_includes @response.body, 'please re-enter it separately if needed'
  end

  test 'shows no sensitive-fields warning for an ordinary stash' do
    stash_a_pending_resubmission
    get pending_resubmission_path
    assert_response :success
    assert_not_includes @response.body, 'please re-enter it separately if needed'
  end

  test 'a stashed value containing a script tag renders escaped, not as raw HTML' do
    stash_a_pending_resubmission(new_name: '<script>alert(1)</script>')
    get pending_resubmission_path
    assert_response :success
    assert_not_includes @response.body, '<script>alert(1)</script>'
    assert_includes @response.body, '&lt;script&gt;alert(1)&lt;/script&gt;'
  end

  # Regression test: there is no :id/:token param on this route, and this
  # action must never read one. If a future change "fixes" show to accept
  # an id from params, matching the usual Rails show idiom, this test
  # fails -- catching the reintroduction of the exact
  # shareable-direct-link vulnerability an earlier draft of this design had.
  test 'a params-supplied id never shows or destroys another session\'s row' do
    other_pending = PendingResubmission.create!(
      resubmit_path: "/en/projects/#{@project.id}",
      resubmit_method: 'PATCH',
      params_json: { 'project[name]' => 'Attacker cannot see this' }.to_json
    )

    # Hardcode the locale prefix here too (see the "no pending resubmission"
    # test above for why): otherwise the assertions below would pass
    # vacuously against an intermediate redirect's near-empty body rather
    # than actually checking the final page.
    get "/en/pending_resubmissions?id=#{other_pending.id}"
    assert_response :redirect
    follow_redirect!
    assert_not_includes @response.body, 'Attacker cannot see this'
    assert PendingResubmission.exists?(other_pending.id)

    get "/en/pending_resubmissions?pending_resubmission_id=#{other_pending.id}"
    assert_response :redirect
    follow_redirect!
    assert_not_includes @response.body, 'Attacker cannot see this'
    assert PendingResubmission.exists?(other_pending.id)
  end
end
