# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user_melissa)
    @other_user = users(:test_user_mark)
    @admin = users(:admin_user)
  end

  test 'should get index' do
    log_in_as(@admin)
    get '/en/users'
    assert_response :success
    assert_includes @response.body, 'All users'
  end

  test 'should get new' do
    get '/en/users/new'
    assert_response :success
    assert_includes @response.body, 'Sign up'
    assert_includes @response.body,
                    'sign up here instead (this creates a custom account'
  end

  test 'should show additional rights on user page when present' do
    project = projects(:one)

    # Ensure the additional rights aren't shown when not there.
    get "/en/users/#{@other_user.id}"
    assert_response :success
    assert_not_includes @response.body, project.name
    assert_not_includes @response.body,
                        I18n.t('users.show.projects_additional_rights')

    # Create additional rights during test, not as a fixture.
    # The fixture would require correct references to *other* fixture ids.
    new_right = AdditionalRight.new(
      user_id: @other_user.id,
      project_id: project.id
    )
    new_right.save!

    # Now that there are additional rights, we should see them
    get "/en/users/#{@other_user.id}"
    assert_response :success
    assert_includes @response.body, project.name
    assert_includes @response.body,
                    I18n.t('users.show.projects_additional_rights')
  end

  test 'indicate admin is admin to admin' do
    log_in_as(@admin)
    get "/en/users/#{@admin.id}"
    assert_response :success
    assert I18n.t('users.show.is_admin').present?
    assert_includes @response.body, I18n.t('users.show.is_admin')
  end

  test 'do NOT indicate non-admin is admin to admin' do
    # This is purely a functional check - ensure we don't give false info
    log_in_as(@admin)
    get "/en/users/#{@user.id}"
    assert_response :success
    assert_not_includes @response.body, I18n.t('users.show.is_admin')
  end

  test 'do NOT indicate admin is admin to non-admin' do
    log_in_as(@user, password: 'password1')
    get "/en/users/#{@user.id}"
    assert_response :success
    assert_not_includes @response.body, I18n.t('users.show.is_admin')
  end

  test 'do NOT indicate admin is admin if not logged in' do
    # No log_in_as
    get "/en/users/#{@user.id}"
    assert_response :success
    assert_not_includes @response.body, I18n.t('users.show.is_admin')
  end

  test 'should NOT show email address when not logged in' do
    get "/en/users/#{@user.id}"
    assert_response :success
    assert_not_includes @response.body, '%40example.com'
    assert_not_includes @response.body, '@example.com'
    # We also want to make sure we don't cache this
    assert_equal 'noindex', @response.headers['X-Robots-Tag']
    # You might think we should just use no-store without private, but
    # some systems (including Fastly) ignore no-store, so both are needed.
    assert_equal 'private, no-store', @response.headers['Cache-Control']
  end

  test 'JSON provides reasonable results when not logged in, but NOT email' do
    get "/en/users/#{@user.id}.json"
    assert_response :success
    assert_equal '{', @response.body[0]
    assert_not_includes @response.body, 'example.com' # Must NOT include email
    json_response = JSON.parse(@response.body)
    assert_equal @user.id, json_response['id']
    assert_not_includes json_response, 'email'
  end

  test 'should NOT show email address when logged in as another user' do
    log_in_as(@other_user)
    get "/en/users/#{@user.id}"
    assert_response :success
    assert_not_includes @response.body, '%40example.com'
    assert_not_includes @response.body, '@example.com'
    assert_equal 'private, no-store', @response.headers['Cache-Control']
  end

  test 'JSON should NOT show email address when logged in as another user' do
    log_in_as(@other_user)
    get "/en/users/#{@user.id}.json"
    assert_response :success
    assert_not_includes @response.body, 'example.com'
    assert_equal 'private, no-store', @response.headers['Cache-Control']
    json_response = JSON.parse(@response.body)
    assert_equal @user.id, json_response['id']
    assert_not_includes json_response, 'email'
  end

  # This is a change, due to the EU General Data Protection Regulation (GDPR)
  # requirement to support "right of access" (users must be able to see
  # the personal data we record about them).
  # We originally didn't do this, since obviously users already know their
  # email addresses, and we wanted to reduce the risk of leaks of this
  # data. That said, we aren't trying to *hide* information about users from
  # themselves, and showing this information appears to be the expectation.
  test 'should show email address of self when logged in as self (GDPR)' do
    log_in_as(@user, password: 'password1')
    get "/en/users/#{@user.id}"
    assert_response :success
    assert_includes @response.body, 'mailto:melissa%40example.com'
    assert_equal 'private, no-store', @response.headers['Cache-Control']
  end

  test 'should show email address when logged in as admin' do
    log_in_as(@admin)
    get "/en/users/#{@user.id}"
    assert_response :success
    assert_includes @response.body, 'mailto:melissa%40example.com'
    assert_equal 'private, no-store', @response.headers['Cache-Control']
  end

  test 'JSON should show email address when logged in as admin' do
    log_in_as(@admin)
    # We can also use ".json" in the URL; we vary it here so we also test
    # that both URL formats work.
    get "/en/users/#{@user.id}?format=json"
    assert_response :success
    assert_includes @response.body, 'melissa@example.com'
    assert_equal 'private, no-store', @response.headers['Cache-Control']
  end

  test 'should redirect edit when not logged in' do
    get "/en/users/#{@user.id}/edit"
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'can create local user' do
    # NOTE: We don't rate limit *creating* a local user, but we have
    # additional requirements for actual *activation* of local user accounts.
    VCR.use_cassette('can_create_local_user') do
      # This will produce a "create" call on the controller
      post '/en/users', params: {
        user: { name: 'Not here', email: 'nonsense@example.org' }
      }
    end
    assert_response 302
    assert_redirected_to root_url
    @new_user = User.find_by(email: 'nonsense@example.org')
    assert_not_nil @new_user
    assert 'Not here', @new_user.name
  end

  # TODO: Also accept post '/en/users/' - the router should be more flexible.

  test 'cannot create local user if login disabled' do
    # NOTE: This test is NOT thread-safe, it manipulates a global variable
    deny_login_old = Rails.application.config.deny_login
    Rails.application.config.deny_login = true

    VCR.use_cassette('cannot_create_local_user_if_login_disabled') do
      # This will produce a "create" call on the controller
      post '/en/users', params: {
        user: { name: 'Not here', email: 'nonsense@example.org' }, locale: :en
      }
    end
    assert '403', response.code

    Rails.application.config.deny_login = deny_login_old
  end

  test 'should redirect update when not logged in' do
    # This becomes an 'update' on the users controller
    patch "/en/users/#{@user.id}", params: {
      user: { name: @user.name, email: @user.email }
    }
    assert_redirected_to login_url
  end

  test 'should redirect edit when logged in as wrong user' do
    log_in_as(@other_user)
    get "/en/users/#{@user.id}/edit"
    assert_redirected_to root_url
    follow_redirect!
    assert_includes @response.body, 'Sorry, you are not allowed to do that.'
    my_assert_select '.alert-danger', 'Sorry, you are not allowed to do that.'
  end

  test 'should redirect update when logged in as wrong user' do
    log_in_as(@other_user)
    patch "/en/users/#{@user.id}", params: {
      user: { name: @user.name, email: @user.email }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_includes @response.body, 'Sorry, you are not allowed to do that.'
    my_assert_select '.alert-danger', 'Sorry, you are not allowed to do that.'
  end

  test 'should update user when logged in as admin' do
    new_name = @user.name + '_updated'
    log_in_as(@admin)
    VCR.use_cassette('should_update_user_when_logged_in_as_admin') do
      patch "/en/users/#{@user.id}", params: { user: { name: new_name } }
    end
    follow_redirect!
    my_assert_select '.alert-success', 'Profile updated'
    @user.reload
    assert_equal @user.name, new_name
  end

  test 'should be able to change locale' do
    log_in_as(@user, password: 'password1')
    VCR.use_cassette('should_be_able_to_change_locale') do
      patch "/en/users/#{@user.id}", params: {
        user: { preferred_locale: 'fr' }
      }
    end
    # The redirected URL has form "/fr/users/ID", not "?id=...".
    assert_redirected_to users_path(locale: 'fr') + "/#{@user.id}"
    follow_redirect!
    my_assert_select '.alert-success', 'Profil mis à jour'
    # Check that the database has been properly updated:
    @user.reload
    assert_equal 'fr', @user.preferred_locale
  end

  test 'should redirect destroy when not logged in' do
    assert_no_difference 'User.count' do
      delete "/en/users/#{@user.id}"
    end
    assert_redirected_to login_url
  end

  test 'should redirect destroy when logged in as wrong non-admin user' do
    log_in_as(@other_user)
    assert_no_difference 'User.count' do
      delete "/en/users/#{@user.id}"
    end
    assert_redirected_to root_url
  end

  test 'admin should be able to destroy a user without projects' do
    log_in_as(@admin)
    assert_difference('User.count', -1) do
      delete "/en/users/#{@other_user.id}"
    end
    assert_redirected_to root_url
  end

  test 'should be able to destroy self without projects (GDPR)' do
    # EU General Data Protection Regulation (GDPR) requires users be able to
    # erase information about themselves.
    log_in_as(@other_user)
    assert session.key?('user_id') # Current session has a user_id
    assert @other_user.id, session['user_id']
    assert session.key?('session_id') # Current session has a user_id
    old_session_id = session['session_id']
    assert_difference('User.count', -1) do
      delete "/en/users/#{@other_user.id}"
    end
    assert_not session.key?('user_id')
    # New session has been initiated
    assert_not_equal old_session_id, session['session_id']
    assert_redirected_to root_url
    get root_url
    my_assert_select '.alert-success', 'User deleted.'
    assert_not session.key?('user_id')
    # TODO: The session key is restored here. It won't matter,
    # since it lacks a user_id, but it's weird. Should fix in the long term.
    # refute session.key?('session_id')
  end

  test 'should not be able to destroy self if have projects' do
    log_in_as(@user, password: 'password1')
    assert_no_difference 'User.count' do
      delete "/en/users/#{@user.id}"
    end
    assert_response 302
    follow_redirect!
    assert_response 200
    my_assert_select '.alert-danger', 'Cannot delete a user who owns projects.'
  end

  test 'admin should not be able to destroy user if have projects' do
    log_in_as(@admin)
    assert_no_difference 'User.count' do
      delete "/en/users/#{@user.id}"
    end
    assert_redirected_to user_path(id: @user.id)
    follow_redirect!
    my_assert_select '.alert-danger', 'Cannot delete a user who owns projects.'
  end

  test 'admin should be able to destroy self without projects' do
    log_in_as(@admin)
    assert_difference('User.count', -1) do
      delete "/en/users/#{@admin.id}"
    end
    assert_redirected_to root_url
    follow_redirect!
    my_assert_select '.alert-success', 'User deleted.'
  end
end
# rubocop:enable Metrics/ClassLength
