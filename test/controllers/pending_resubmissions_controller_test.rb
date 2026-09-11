# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Tests PendingResubmissionsController#show (docs/login-session-implementation.md
# section 15, docs/login-session-18.md step 18): stashed-submission lookup
# is keyed only by session[:pending_resubmission_token], never by
# anything in params. Since docs/login-session-evaluation.md finding #4, #show also no
# longer destroys the row or clears that session key itself: it's only
# ever consumed by ApplicationController#finalize_pending_resubmission,
# once the resume form is actually resubmitted (see
# test/integration/pending_resubmission_test.rb for that full round trip).
class PendingResubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @user = users(:test_user) # local user, owns @project
  end

  # Triggers the real stash path (a logged-out PATCH to a project edit
  # action) rather than constructing a PendingResubmission by hand, then
  # logs in for real carrying the resulting token, since that's the only
  # place session[:pending_resubmission_token] gets written (docs/
  # login-session-18.md "Step 21"). Deliberately not `session[key] =
  # value` here: ActionDispatch::IntegrationTest does not reliably
  # persist a direct session assignment made between requests, only
  # mutations the application itself makes during an actual
  # request/response cycle, so this file is about
  # PendingResubmissionsController#show, and gets there through a real
  # (if minimal) login rather than poking session directly. Stops right
  # after the login's own redirect, without following it, so the token
  # is present but not yet consumed, ready for the test's own first
  # `get pending_resubmission_path`.
  def stash_a_pending_resubmission(new_name: 'Stashed name')
    patch "/en/projects/#{@project.id}", params: {
      project: { name: new_name }
    }
    log_in_carrying_pending_resubmission_token
    PendingResubmission.last
  end

  def pending_resubmission_token_from_redirect
    Rack::Utils.parse_nested_query(URI.parse(response.location).query)[
      'pending_resubmission_token'
    ]
  end

  def log_in_carrying_pending_resubmission_token
    token = pending_resubmission_token_from_redirect
    post login_path, params: {
      session: {
        email: @user.email, password: 'password', provider: 'local',
        pending_resubmission_token: token
      }
    }
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

  test 'a second visit before resubmitting still shows the same stash' do
    # Simulates the recovery path docs/login-session-evaluation.md finding #4 exists for: a
    # closed tab, or back-then-forward, before ever clicking "Resume."
    stash_a_pending_resubmission(new_name: 'Resubmit me')
    get pending_resubmission_path
    assert_response :success

    get pending_resubmission_path
    assert_response :success
    assert_select "input[type='hidden'][name='project[name]'][value='Resubmit me']"
  end

  test 'a mere view does not destroy the row or clear the session token' do
    pending = stash_a_pending_resubmission
    get pending_resubmission_path
    assert PendingResubmission.exists?(pending.id)
    assert_not_nil session[:pending_resubmission_token]
  end

  test 'resubmitting the stash destroys it and clears the session token' do
    pending = stash_a_pending_resubmission(new_name: 'Resubmit me')
    get pending_resubmission_path
    token = session[:pending_resubmission_token]

    # This is what clicking "Resume" actually sends: the view's hidden
    # pending_resubmission_token field alongside the stashed project
    # fields, straight to the original resubmit_path/method, not back
    # through PendingResubmissionsController at all.
    patch pending.resubmit_path, params: {
      project: { name: 'Resubmit me' }, pending_resubmission_token: token
    }
    assert_not PendingResubmission.exists?(pending.id)
    assert_nil session[:pending_resubmission_token]
  end

  test 'shows sensitive-fields-dropped warning when email/password were stripped' do
    patch "/en/users/#{@user.id}", params: {
      user: { name: @user.name, email: @user.email }
    }
    log_in_carrying_pending_resubmission_token
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

  # Regression test: there is no :id/:token param this action itself
  # reads, and #show must never read one to decide what to *display*. If a
  # future change "fixes" show to accept an identifier from params,
  # matching the usual Rails show idiom, this test fails, catching the
  # reintroduction of the exact shareable-direct-link vulnerability an
  # earlier draft of this design had. (This is unrelated to
  # ApplicationController#finalize_pending_resubmission, which does read a
  # pending_resubmission_token param, but only to destroy a row, never to
  # show one. 'pending_resubmission_token' here is also deliberately set
  # to hashed_random_id, not the real raw token, so it can't match via
  # that mechanism either.)
  test 'a params-supplied identifier never shows or destroys another session\'s row' do
    other_pending = PendingResubmission.create!(
      resubmit_path: "/en/projects/#{@project.id}",
      resubmit_method: 'PATCH',
      params_json: { 'project[name]' => 'Attacker cannot see this' }.to_json,
      hashed_random_id: PendingResubmission.digest(SecureRandom.urlsafe_base64)
    )

    # Hardcode the locale prefix here too (see the "no pending resubmission"
    # test above for why): otherwise the assertions below would pass
    # vacuously against an intermediate redirect's near-empty body rather
    # than actually checking the final page. Cover every identifier this
    # row actually has (its own id, and its hashed_random_id) under every
    # param name a "fixed" show might plausibly read.
    %w[id hashed_random_id pending_resubmission_token].each do |param_name|
      value = param_name == 'id' ? other_pending.id : other_pending.hashed_random_id
      get "/en/pending_resubmissions?#{param_name}=#{value}"
      assert_response :redirect
      follow_redirect!
      assert_not_includes @response.body, 'Attacker cannot see this'
      assert PendingResubmission.exists?(other_pending.id)
    end
  end
end
