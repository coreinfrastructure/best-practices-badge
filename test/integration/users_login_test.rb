require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
  end

  test 'login with invalid information' do
    get login_path
    assert_template 'sessions/new'
    post login_path,
         provider: 'local',
         session: { email: 'unknown@example.org', password: 'bad_password' }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  # See the comments on test_helper.rb method log_in_as()
  test 'login with valid information and then logout' do
    # To skip: skip('message')
    get login_path
    assert_template 'sessions/new'

    log_in_as @user

    assert logged_in?
    # If we redirect users to @user on login:
    # assert_redirected_to @user
    # follow_redirect!
    # assert_template 'users/show'
    # assert_select 'a[href=?]', login_path, count: 0
    # assert_select 'a[href=?]', logout_path
    # assert_select 'a[href=?]', user_path(@user)

    delete logout_path
    assert_not logged_in?
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'a[href=?]', login_path
    assert_select 'a[href=?]', logout_path,      count: 0
    assert_select 'a[href=?]', user_path(@user), count: 0
  end
end
