# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
# TODO: ActionController::TestCase is obsolete. This should switch to using
# ActionDispatch::IntegrationTest and then remove rails-controller-testing.
# See: https://github.com/rails/rails/issues/22496
class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:test_user_melissa)
    @other_user = users(:test_user_mark)
    @admin = users(:admin_user)
  end

  test 'should get index' do
    log_in_as(@admin)
    get :index, params: { locale: :en }
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test 'should get new' do
    get :new, params: { locale: :en }
    assert_response :success
  end

  test 'should show additional rights on user page when present' do
    project = projects(:one)

    get :show, params: { id: @other_user, locale: :en }
    assert_response :success
    refute_includes @response.body, project.name
    refute_includes @response.body,
                    I18n.t('users.show.projects_additional_rights')

    # Create additional rights during test, not as a fixture.
    # The fixture would require correct references to *other* fixture ids.
    new_right = AdditionalRight.new(
      user_id: @other_user.id,
      project_id: project.id
    )
    new_right.save!

    get :show, params: { id: @other_user, locale: :en }
    assert_response :success
    assert_includes @response.body, project.name
    assert_includes @response.body,
                    I18n.t('users.show.projects_additional_rights')
  end

  test 'indicate admin is admin to admin' do
    log_in_as(@admin)
    get :show, params: { id: @admin, locale: :en }
    assert_response :success
    assert I18n.t('users.show.is_admin').present?
    assert_includes @response.body,
                    I18n.t('users.show.is_admin')
  end

  test 'do NOT indicate non-admin is admin to admin' do
    log_in_as(@admin)
    get :show, params: { id: @user, locale: :en }
    assert_response :success
    refute_includes @response.body,
                    I18n.t('users.show.is_admin')
  end

  test 'do NOT indicate admin is admin to non-admin' do
    log_in_as(@user)
    get :show, params: { id: @admin, locale: :en }
    assert_response :success
    refute_includes @response.body,
                    I18n.t('users.show.is_admin')
  end

  test 'do NOT indicate admin is admin if not logged in' do
    # No log_in_as
    get :show, params: { id: @admin, locale: :en }
    assert_response :success
    refute_includes @response.body,
                    I18n.t('users.show.is_admin')
  end

  test 'should NOT show email address when not logged in' do
    get :show, params: { id: @user, locale: :en }
    assert_response :success
    refute_includes @response.body, '%40example.com'
    refute_includes @response.body, '@example.com'
    assert_equal 'noindex', @response.headers['X-Robots-Tag']
    assert_equal 'no-cache, no-store',
                 @response.headers['Cache-Control']
  end

  test 'JSON should NOT show email address when not logged in' do
    get :show, params: { id: @user, format: :json, locale: :en }
    assert_response :success
    refute_includes @response.body, 'example.com'
  end

  test 'JSON provides reasonable results when not logged in' do
    get :show, params: { id: @user, format: :json, locale: :en }
    assert_response :success
    assert_equal '{', @response.body[0]
    json_response = JSON.parse(@response.body)
    assert_equal @user.id, json_response['id']
  end

  test 'should NOT show email address when logged in as another user' do
    log_in_as(@other_user)
    get :show, params: { id: @user, locale: :en }
    assert_response :success
    refute_includes @response.body, '%40example.com'
    refute_includes @response.body, '@example.com'
    assert_equal 'no-cache, no-store',
                 @response.headers['Cache-Control']
  end

  test 'JSON should NOT show email address when logged in as another user' do
    log_in_as(@other_user)
    get :show, params: { id: @user, format: :json, locale: :en }
    assert_response :success
    refute_includes @response.body, 'example.com'
    assert_equal 'no-cache, no-store',
                 @response.headers['Cache-Control']
  end

  # This is a change, due to the EU General Data Protection Regulation (GDPR)
  # requirement to support "right of access" (users must be able to see
  # the personal data we record about them).
  # We originally didn't do this, since obviously users already know their
  # email addresses, and we wanted to reduce the risk of leaks of this
  # data.
  test 'should show email address of self when logged in as self (GDPR)' do
    log_in_as(@user)
    get :show, params: { id: @user, locale: :en }
    assert_response :success
    assert_includes @response.body, 'mailto:melissa%40example.com'
    assert_equal 'no-cache, no-store',
                 @response.headers['Cache-Control']
  end

  test 'should show email address when logged in as admin' do
    log_in_as(@admin)
    get :show, params: { id: @user, locale: :en }
    assert_response :success
    assert_includes @response.body, 'mailto:melissa%40example.com'
    assert_equal 'no-cache, no-store',
                 @response.headers['Cache-Control']
  end

  test 'JSON should show email address when logged in as admin' do
    log_in_as(@admin)
    get :show, params: { id: @user, format: :json, locale: :en }
    assert_response :success
    assert_includes @response.body, 'melissa@example.com'
    assert_equal 'no-cache, no-store',
                 @response.headers['Cache-Control']
  end

  test 'should redirect edit when not logged in' do
    get :edit, params: { id: @user, locale: :en }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'can create local user' do
    VCR.use_cassette('can_create_local_user') do
      patch :create, params: {
        user: { name: 'Not here', email: 'nonsense@example.org' }, locale: :en
      }
    end
    assert '302', response.code
  end

  test 'cannot create local user if login disabled' do
    deny_login_old = Rails.application.config.deny_login
    Rails.application.config.deny_login = true

    VCR.use_cassette('cannot_create_local_user_if_login_disabled') do
      patch :create, params: {
        user: { name: 'Not here', email: 'nonsense@example.org' }, locale: :en
      }
    end
    assert '403', response.code

    Rails.application.config.deny_login = deny_login_old
  end

  test 'should redirect update when not logged in' do
    patch :update, params: {
      id: @user, user: { name: @user.name, email: @user.email }, locale: :en
    }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect edit when logged in as wrong user' do
    log_in_as(@other_user)
    get :edit, params: { id: @user, locale: :en }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test 'should redirect update when logged in as wrong user' do
    log_in_as(@other_user)
    patch :update, params: {
      id: @user, user: { name: @user.name, email: @user.email }, locale: :en
    }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test 'should update user when logged in as admin' do
    new_name = @user.name + '_updated'
    log_in_as(@admin)
    VCR.use_cassette('should_update_user_when_logged_in_as_admin') do
      patch :update, params: {
        id: @user, user: { name: new_name }, locale: :en
      }
    end
    assert_not_empty flash
    @user.reload
    assert_equal @user.name, new_name
  end

  test 'should be able to change locale' do
    log_in_as(@user)
    VCR.use_cassette('should_be_able_to_change_locale') do
      patch :update, params: {
        id: @user, user: { preferred_locale: 'fr' }, locale: :en
      }
    end
    assert_not_empty flash # Success message
    @user.reload
    assert_equal 'fr', @user.preferred_locale
    assert_redirected_to users_path(locale: 'fr') + "/#{@user.id}"
  end

  test 'should redirect destroy when not logged in' do
    assert_no_difference 'User.count' do
      delete :destroy, params: { id: @user, locale: :en }
    end
    assert_redirected_to login_url
  end

  test 'should redirect destroy when logged in as wrong non-admin user' do
    log_in_as(@other_user)
    assert_no_difference 'User.count' do
      delete :destroy, params: { id: @user, locale: :en }
    end
    assert_redirected_to root_url
  end

  test 'admin should be able to destroy a user without projects' do
    log_in_as(@admin)
    assert_difference('User.count', -1) do
      delete :destroy, params: { id: @other_user, locale: :en }
    end
    assert_not_empty flash
  end

  test 'should be able to destroy self without projects (GDPR)' do
    # EU General Data Protection Regulation (GDPR) requires users be able to
    # erase information about themselves.
    log_in_as(@other_user)
    assert_difference('User.count', -1) do
      delete :destroy, params: { id: @other_user, locale: :en }
    end
    assert_not_empty flash
  end

  test 'should not be able to destroy self if have projects' do
    log_in_as(@user)
    assert_no_difference 'User.count' do
      delete :destroy, params: { id: @user, locale: :en }
    end
  end

  test 'admin should not be able to destroy user if have projects' do
    log_in_as(@admin)
    assert_no_difference 'User.count' do
      delete :destroy, params: { id: @user, locale: :en }
    end
  end

  test 'admin should be able to destroy self without projects' do
    log_in_as(@admin)
    assert_difference('User.count', -1) do
      delete :destroy, params: { id: @admin, locale: :en }
    end
  end
end
# rubocop:enable Metrics/ClassLength
