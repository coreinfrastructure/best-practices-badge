# frozen_string_literal: true

require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
  end

  test 'unsuccessful edit - email' do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: { user: {
      name:  '',
      email: 'foo@invalid',
      password:              '',
      password_confirmation: ''
    } }
    assert_template 'users/edit'
  end

  test 'unsuccessful edit - password' do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: { user: {
      name:  '',
      email: '',
      password:              'password',
      password_confirmation: 'password'
    } }
    assert_template 'users/edit'
  end

  test 'successful edit - name/email' do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    name  = 'Foo Bar'
    email = 'foo@bar.com'
    patch user_path(@user), params: { user: {
      name:  name,
      email: email,
      password:              '',
      password_confirmation: ''
    } }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name,  @user.name
    assert_equal email, @user.email
  end

  test 'successful edit - password' do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    name  = 'Foo Bar'
    email = 'foo@bar.com'
    patch user_path(@user), params: { user: {
      name:  name,
      email: email,
      password:              'Agoodp@$$word',
      password_confirmation: 'Agoodp@$$word'
    } }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name,  @user.name
    assert_equal email, @user.email
  end
end
