require 'test_helper'

class UsersManipulateProjectTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
  end

  test 'logged-in user adds a project' do
    # Go to login_path to initialize the session
    get login_path
    log_in_as @user

    get '/projects/new'
    assert_response :success
    assert_template 'projects/new'

    #  assert_select 'a[href=?]', login_path, count: 0
    #  assert_select 'a[href=?]', logout_path
    #  assert_select 'a[href=?]', user_path(@user)
    #  delete logout_path
    #  assert_not logged_in?
    #  assert_redirected_to root_url
    #  follow_redirect!
    #  assert_select 'a[href=?]', login_path
    #  assert_select 'a[href=?]', logout_path,      count: 0
    #  assert_select 'a[href=?]', user_path(@user), count: 0
  end
end
