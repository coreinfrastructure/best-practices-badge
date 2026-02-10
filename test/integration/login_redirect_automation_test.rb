# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Tests that unauthenticated users visiting project edit URLs with
# automation query params are redirected to login, and after successful
# login are sent back to the original URL with params preserved.
class LoginRedirectAutomationTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @user = users(:test_user) # local user, owns project :one
  end

  test 'unauthenticated edit redirects to login not root' do
    get "/en/projects/#{@project.id}/passing/edit"
    assert_response :redirect
    assert_redirected_to login_path
  end

  test 'unauthenticated edit stores forwarding URL in session' do
    edit_url = "/en/projects/#{@project.id}/passing/edit?description=New+desc"
    get edit_url
    assert_response :redirect
    assert_redirected_to login_path
    # Session should contain the full original URL with query params
    forwarding = session[:forwarding_url]
    assert forwarding.present?, 'forwarding_url should be stored in session'
    assert_includes forwarding, "projects/#{@project.id}/passing/edit"
    assert_includes forwarding, 'description=New+desc'
  end

  test 'local user login redirects back to edit URL with automation params' do
    edit_path = "/en/projects/#{@project.id}/passing/edit" \
                '?description=Automated+description'
    # Step 1: Visit edit page while not logged in
    get edit_path
    assert_response :redirect
    assert_redirected_to login_path

    # Step 2: Log in as the project owner (local user)
    post login_path, params: {
      session: {
        email: @user.email, password: 'password',
        provider: 'local', remember_me: '0'
      }
    }
    assert_response :redirect

    # Step 3: Verify redirect goes back to edit URL with automation params
    assert user_logged_in?
    redirect_location = response.location
    assert_includes redirect_location,
                    "projects/#{@project.id}/passing/edit"
    assert_includes redirect_location, 'description=Automated+description'

    # Step 4: Follow redirect and confirm we get the edit form
    follow_redirect!
    assert_response :success
  end

  test 'local user login redirects to edit with multiple automation params' do
    edit_path = "/en/projects/#{@project.id}/passing/edit" \
                '?description=Auto+desc&name=Auto+name'
    get edit_path
    assert_redirected_to login_path

    post login_path, params: {
      session: {
        email: @user.email, password: 'password',
        provider: 'local', remember_me: '0'
      }
    }

    redirect_location = response.location
    assert_includes redirect_location, 'description=Auto+desc'
    assert_includes redirect_location, 'name=Auto+name'
  end

  test 'unauthorized user gets redirected to project show after login' do
    other_user = users(:test_user_melissa) # password is 'password1'
    edit_path = "/en/projects/#{@project.id}/passing/edit" \
                '?description=Automated+description'

    # Step 1: Visit edit page while not logged in
    get edit_path
    assert_redirected_to login_path

    # Step 2: Log in as a different user who does NOT own this project
    post login_path, params: {
      session: {
        email: other_user.email, password: 'password1',
        provider: 'local', remember_me: '0'
      }
    }
    assert_response :redirect

    # Step 3: Follow the redirect to the edit URL
    follow_redirect!

    # Step 4: can_edit_else_redirect should redirect to project show page
    # because user is logged in but not authorized, with flash message
    assert_response :redirect
    assert_redirected_to project_section_path(@project, 'passing')
    assert_equal 'You are not authorized to edit this project.',
                 flash[:danger]
  end

  test 'unauthenticated edit with baseline section stores correct URL' do
    edit_url = "/en/projects/#{@project.id}/baseline-1/edit" \
               '?description=Baseline+desc'
    get edit_url
    assert_redirected_to login_path
    forwarding = session[:forwarding_url]
    assert_includes forwarding, 'baseline-1/edit'
    assert_includes forwarding, 'description=Baseline+desc'
  end
end
