# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class ProjectsControllerSpecialTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
  end

  test 'should fail to edit due to old session without remember token' do
    # Log in without remember_me
    log_in_as(@project.user, remember_me: '0')
    # Time travel past session timeout (48 hours + 1 second)
    travel 49.hours do
      get "/en/projects/#{@project.id}/passing/edit"
      assert_response :found
      # After session timeout without remember token, user is logged out
      # and can_edit_else_redirect redirects to login with return_to param
      assert_match %r{/en/login\?return_to=}, response.location
    end
  end

  test 'should stay logged in with old session if remember token valid' do
    # Log in WITH remember_me (the default)
    log_in_as(@project.user, remember_me: '1')
    original_login_session_id = session[:login_session_id]
    # Time travel past session timeout (48 hours + 1 second)
    travel 49.hours do
      get "/en/projects/#{@project.id}/passing/edit"
      # Remember token should auto-login the user despite session timeout
      # so edit page should load successfully
      assert_response :success
      # Verify user is still logged in (session was recreated by remember token)
      assert_not_nil session[:login_session_id]
      assert_equal @project.user.id, logged_in_user_id
      # The idle-expired LoginSession row is destroyed, not revived: the
      # silent remember-me restore creates a genuinely new one (design doc
      # section 3/7's write-cost note), it does not reset the old row's
      # last_used_at.
      assert_not_equal original_login_session_id, session[:login_session_id]
      assert_not LoginSession.exists?(
        session_id_digest: LoginSession.digest(original_login_session_id)
      )
    end
  end

  test 'should fail to edit due to absolute session cap without remember token' do
    # Log in without remember_me
    log_in_as(@project.user, remember_me: '0')
    # Backdate created_at past the 30-day absolute cap, while last_used_at
    # stays recent -- isolates the absolute-cap branch of
    # setup_authentication_state from the idle-timeout branch tested above.
    LoginSession.find_by_session_id(session[:login_session_id])
                .update_columns(created_at: SessionsHelper::ABSOLUTE_SESSION_AGE.ago.utc - 1.minute)
    get "/en/projects/#{@project.id}/passing/edit"
    assert_response :found
    assert_match %r{/en/login\?return_to=}, response.location
  end

  test 'should stay logged in past absolute session cap if remember token valid' do
    # Log in WITH remember_me (the default)
    log_in_as(@project.user, remember_me: '1')
    original_login_session_id = session[:login_session_id]
    LoginSession.find_by_session_id(original_login_session_id)
                .update_columns(created_at: SessionsHelper::ABSOLUTE_SESSION_AGE.ago.utc - 1.minute)
    get "/en/projects/#{@project.id}/passing/edit"
    # Remember token should auto-login the user despite the absolute cap,
    # exactly as it does for an idle-timed-out session.
    assert_response :success
    assert_not_nil session[:login_session_id]
    assert_equal @project.user.id, logged_in_user_id
    assert_not_equal original_login_session_id, session[:login_session_id]
    assert_not LoginSession.exists?(
      session_id_digest: LoginSession.digest(original_login_session_id)
    )
  end

  test 'forwarding_url does not survive the idle-expiry + remember-me path' do
    # Log in WITH remember_me, then visit a page that sets forwarding_url
    # unconditionally (ProjectsController#new) so it's present in the
    # session while the login is still nominally valid.
    log_in_as(@project.user, remember_me: '1')
    get '/en/projects/new'
    assert_equal new_project_url(locale: :en), session[:forwarding_url]

    # Time travel past session timeout (48 hours + 1 second): the login
    # becomes idle-expired, so the next request's setup_authentication_state
    # destroys it and calls reset_session (wiping forwarding_url) *before*
    # falling through to try_remember_token_login/log_in. Confirm (rather
    # than assume) that forwarding_url does NOT survive this path, unlike
    # the ordinary POST /login path where log_in relocalizes a pre-existing
    # one.
    travel 49.hours do
      get "/en/projects/#{@project.id}/passing/edit"
      assert_response :success
      assert_equal @project.user.id, logged_in_user_id
      assert_nil session[:forwarding_url]
    end
  end
end
