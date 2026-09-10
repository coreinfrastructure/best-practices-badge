# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Full round-trip tests for docs/login-session-implementation.md section 15:
# a stashed pending resubmission must survive both local login and GitHub
# OAuth login (which leaves the site entirely and comes back), because
# counter_fixation's reset_session runs unconditionally on every login
# attempt, success or failure.
class PendingResubmissionTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @user = users(:test_user) # local user, owns @project
  end

  test 'local login carries the stash through and the resume button resubmits it' do
    new_name = "#{@project.name}_resubmitted"

    patch "/en/projects/#{@project.id}", params: { project: { name: new_name } }
    assert_match %r{/en/login\?return_to=}, response.location
    assert_not_nil session[:pending_resubmission_token]

    post login_path, params: {
      session: { email: @user.email, password: 'password', provider: 'local' }
    }
    # session[:pending_resubmission_token] takes priority over the login
    # form's own return_to, per successful_login.
    assert_redirected_to pending_resubmission_path
    # counter_fixation resets the session on every login attempt; confirm
    # the pending resubmission token actually survived that reset rather
    # than this redirect happening to be right for some other reason.
    assert_not_nil session[:pending_resubmission_token]

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
    pending_token = session[:pending_resubmission_token]
    assert_not_nil pending_token

    post login_path, params: {
      session: { email: @user.email, password: 'wrong-password', provider: 'local' }
    }
    assert_response :success # re-renders the login form; login failed
    assert_equal pending_token, session[:pending_resubmission_token]
    assert PendingResubmission.exists?(hashed_random_id: PendingResubmission.digest(pending_token))
  end

  test 'github oauth login carries the stash across the round trip' do
    patch "/en/projects/#{@project.id}", params: { project: { name: 'via github' } }
    assert_not_nil session[:pending_resubmission_token]

    github_user = users(:github_user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(
      :github,
      'provider' => 'github',
      'uid' => github_user.uid || '12345',
      'credentials' => { 'token' => 'test_token' },
      'info' => {
        'name' => github_user.name,
        'nickname' => github_user.nickname,
        'email' => github_user.email
      }
    )
    get '/auth/github/callback'
    assert_redirected_to pending_resubmission_path
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end
end
