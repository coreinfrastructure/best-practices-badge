# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Full round-trip tests for docs/login-session-implementation.md section 15:
# a stashed pending resubmission must survive both local login and GitHub
# OAuth login (which leaves the site entirely and comes back), because
# counter_fixation's reset_session runs unconditionally on every login
# attempt, success or failure. Since docs/login-session-18.md's "Step 21",
# the token rides the login redirect's own request params, the same way a
# real browser's login-form hidden field or GitHub auth link would carry it,
# rather than session; these tests thread it through that way instead of
# reading it back from session mid-flow.
class PendingResubmissionTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @user = users(:test_user) # local user, owns @project
  end

  test 'local login carries the stash through and the resume button resubmits it' do
    new_name = "#{@project.name}_resubmitted"

    patch "/en/projects/#{@project.id}", params: { project: { name: new_name } }
    token = pending_resubmission_token_from_redirect
    assert_not_nil token
    assert_nil session[:pending_resubmission_token] # not written until login succeeds

    post login_path, params: {
      session: {
        email: @user.email, password: 'password', provider: 'local',
        pending_resubmission_token: token
      }
    }
    assert_redirected_to pending_resubmission_path
    # counter_fixation resets the session on every login attempt; confirm
    # the token actually survived via this login's own request param,
    # rather than this redirect happening to be right for some other
    # reason.
    assert_equal token, session[:pending_resubmission_token]

    follow_redirect!
    assert_response :success
    assert_select "input[type='hidden'][name='project[name]'][value='#{new_name}']"

    # Click "Resume saving your changes."
    patch "/en/projects/#{@project.id}", params: { project: { name: new_name } }
    @project.reload
    assert_equal new_name, @project.name
  end

  test 'a failed login attempt does not lose the stash' do
    patch "/en/projects/#{@project.id}", params: { project: { name: 'attempt' } }
    token = pending_resubmission_token_from_redirect
    assert_not_nil token

    post login_path, params: {
      session: {
        email: @user.email, password: 'wrong-password', provider: 'local',
        pending_resubmission_token: token
      }
    }
    assert_response :success # re-renders the login form; login failed
    # Login failed, so this never reached successful_login; the token
    # survives only because the re-rendered form echoes back this same
    # request's own pending_resubmission_token param, ready for a retry
    # with the correct password, not via session.
    assert_select "input[type='hidden'][name='session[pending_resubmission_token]']" \
                  "[value='#{token}']"
    assert PendingResubmission.exists?(hashed_random_id: PendingResubmission.digest(token))
  end

  test 'github oauth login carries the stash across the round trip' do
    patch "/en/projects/#{@project.id}", params: { project: { name: 'via github' } }
    token = pending_resubmission_token_from_redirect
    assert_not_nil token

    github_user = users(:github_user)
    # Both github-provider fixtures leave :uid unset (NULL for both), so
    # give it a real one first rather than relying on the mock's fallback
    # to disambiguate.
    github_user.update!(uid: 'github-test-uid')
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(
      :github,
      'provider' => 'github',
      'uid' => github_user.uid,
      'credentials' => { 'token' => 'test_token' },
      'info' => {
        'name' => github_user.name,
        'nickname' => github_user.nickname,
        'email' => github_user.email
      }
    )
    # Hits the request phase first, with the token as a query param the
    # same way the login page's "Log in with GitHub" link builds it, so
    # OmniAuth's own session['omniauth.params'] round trip actually
    # carries it across the redirect to GitHub and back, rather than this
    # test jumping straight to the callback and skipping that entirely.
    # POST, not GET: OmniAuth 2.x's default allowed_request_methods is
    # [:post] only, matching this app's own link (method: 'post'); a GET
    # here just 404s. The token rides the URL's own query string, not
    # the params: hash, since Rails' post/params: encodes that into the
    # request body, but OmniAuth reads request.GET (query string only),
    # the same as the real link.
    post "/auth/github?pending_resubmission_token=#{ERB::Util.url_encode(token)}"
    assert_response :redirect
    follow_redirect!
    assert_redirected_to pending_resubmission_path
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test 'a login without its own pending_resubmission_token never resumes a leftover one' do
    # Regression guard for the cross-user disclosure docs/login-session-18.md
    # "Step 21" closes: on a shared browser, an earlier abandoned stash must
    # not be resumed by a later, unrelated login that never carried its own
    # pending_resubmission_token param.
    patch "/en/projects/#{@project.id}", params: { project: { name: 'someone else' } }
    assert_not_nil pending_resubmission_token_from_redirect

    post login_path, params: {
      session: { email: @user.email, password: 'password', provider: 'local' }
    }
    assert_response :redirect
    assert_not_equal pending_resubmission_path, URI.parse(response.location).path
    assert_nil session[:pending_resubmission_token]
  end

  private

  # Extracts pending_resubmission_token from the most recent response's
  # redirect location, the same way a browser reads it off the URL it was
  # sent to rather than by peeking at session.
  def pending_resubmission_token_from_redirect
    Rack::Utils.parse_nested_query(URI.parse(response.location).query)[
      'pending_resubmission_token'
    ]
  end
end
