require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    @user = users(:test_user_melissa)
    @other_user = users(:test_user_mark)
    @admin = users(:admin_user)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should redirect edit when not logged in' do
    get :edit, id: @user
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect update when not logged in' do
    patch :update, id: @user, user: { name: @user.name, email: @user.email }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect edit when logged in as wrong user' do
    log_in_as(@other_user)
    get :edit, id: @user
    assert flash.empty?
    assert_redirected_to root_url
  end

  test 'should redirect update when logged in as wrong user' do
    log_in_as(@other_user)
    patch :update, id: @user, user: { name: @user.name, email: @user.email }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test 'should  update user when logged in as admin' do
    new_name = @user.name + '_updated'
    log_in_as(@admin)
    patch :update, id: @user, user: { name: new_name }
    assert_not_empty flash
    @user.reload
    assert_equal @user.name, new_name
  end

  test 'should redirect destroy when not logged in' do
    assert_no_difference 'User.count' do
      delete :destroy, id: @user
    end
    assert_redirected_to root_url
  end

  test 'should redirect destroy when logged in as a non-admin' do
    log_in_as(@other_user)
    assert_no_difference 'User.count' do
      delete :destroy, id: @user
    end
    assert_redirected_to root_url
  end

  test 'should destroy user when logged in as admin' do
    log_in_as(@admin)
    assert_difference('User.count', -1) do
      delete :destroy, id: @other_user
    end
    assert_not_empty flash
  end
end
