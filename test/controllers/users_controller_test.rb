# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:test_user_melissa)
    @other_user = users(:test_user_mark)
    @admin = users(:admin_user)
  end

  test 'should get index' do
    log_in_as(@admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should NOT show email address when not logged in' do
    get :show, params: { id: @user }
    assert_response :success
    refute_includes @response.body, 'mailto:melissa%40example.com'
  end

  test 'should NOT show email address when logged in as another normal user' do
    log_in_as(@other_user)
    get :show, params: { id: @user }
    assert_response :success
    refute_includes @response.body, 'mailto:melissa%40example.com'
  end

  # This is debatable.  It's not really a *problem* if we show users
  # their own email addresses :-).  But the purpose of this display is to
  # allow admins to know who to contact, and users don't need this way to
  # get in touch with themselves.  This also lets us express the rule
  # simply: "Only admins see user email addresses on this page".
  test 'should NOT show email address when logged in as self' do
    log_in_as(@user)
    get :show, params: { id: @user }
    assert_response :success
    refute_includes @response.body, 'mailto:melissa%40example.com'
  end

  test 'should show email address when logged in as admin' do
    log_in_as(@admin)
    get :show, params: { id: @user }
    assert_response :success
    assert_includes @response.body, 'mailto:melissa%40example.com'
  end

  test 'should redirect edit when not logged in' do
    get :edit, params: { id: @user }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect update when not logged in' do
    patch :update, params: {
      id: @user, user: { name: @user.name, email: @user.email }
    }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect edit when logged in as wrong user' do
    log_in_as(@other_user)
    get :edit, params: { id: @user }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test 'should redirect update when logged in as wrong user' do
    log_in_as(@other_user)
    patch :update, params: {
      id: @user, user: { name: @user.name, email: @user.email }
    }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test 'should  update user when logged in as admin' do
    new_name = @user.name + '_updated'
    log_in_as(@admin)
    patch :update, params: { id: @user, user: { name: new_name } }
    assert_not_empty flash
    @user.reload
    assert_equal @user.name, new_name
  end

  test 'should be able to change locale' do
    log_in_as(@user)
    patch :update, params: { id: @user, user: { preferred_locale: 'fr' } }
    assert_not_empty flash # Success message
    @user.reload
    assert_equal 'fr', @user.preferred_locale
    assert_redirected_to users_path(locale: 'fr') + "/#{@user.id}"
  end

  test 'should redirect destroy when not logged in' do
    assert_no_difference 'User.count' do
      delete :destroy, params: { id: @user }
    end
    assert_redirected_to root_url
  end

  test 'should redirect destroy when logged in as a non-admin' do
    log_in_as(@other_user)
    assert_no_difference 'User.count' do
      delete :destroy, params: { id: @user }
    end
    assert_redirected_to root_url
  end

  test 'should destroy user when logged in as admin' do
    log_in_as(@admin)
    assert_difference('User.count', -1) do
      delete :destroy, params: { id: @other_user }
    end
    assert_not_empty flash
  end

  test 'should not be able to destroy self' do
    log_in_as(@admin)
    assert_no_difference 'User.count' do
      delete :destroy, params: { id: @admin }
    end
    assert_not_empty flash
  end
end
# rubocop:enable Metrics/ClassLength
