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

    repo_url = 'https://github.com/linuxfoundation/cii-best-practices-badge'

    VCR.use_cassette('users_manipulate_test') do
      post '/projects',
           'project[project_homepage_url]' => repo_url,
           'project[repo_url]' => repo_url
      assert_response :redirect
      follow_redirect!

      assert_response :success
      assert_template 'projects/edit'

      # Check that returned settings are correct.
      # Note: You can use byebug... css_select to interactively check things.
      assert_select '#project_name[value=?]',
                    'Core Infrastructure Initiative Best Practices Badge'
      assert_select '#project_discussion_status_met[checked]'
      assert_select '#project_contribution_status_met[checked]'
      assert_select '#project_oss_license_status_met[checked]'
      assert_select '#project_oss_license_osi_status_met[checked]'
      assert_select '#project_license_location_status_met[checked]'
      assert_select '#project_repo_track_status_met[checked]'
      assert_select '#project_repo_distributed_status_met[checked]'
      assert_select '#project_release_notes_status_met[checked]'
      assert_select '#project_build_status_met[checked]'
      assert_select '#project_build_common_tools_status_met[checked]'
      assert_select '#project_contribution_status_met[checked]'

      assert_select '#project_static_analysis_status_[checked]' # Unknown.

      # Ensure alternate entries exist but are not checked
      assert_select '#project_repo_distributed_status_'
      assert_select '#project_repo_distributed_status_[checked]', count: 0
      assert_select '#project_repo_distributed_status_unmet'
      assert_select '#project_repo_distributed_status_unmet[checked]', count: 0

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

  test 'logged-in user adds assimilation-official' do
    # Regression test, see:
    # https://github.com/linuxfoundation/cii-best-practices-badge/issues/160
    # Go to login_path to initialize the session
    get login_path
    log_in_as @user

    get '/projects/new'
    assert_response :success
    assert_template 'projects/new'

    repo_url = 'https://github.com/assimilation/assimilation-official'

    VCR.use_cassette('assimilation-official') do
      post '/projects',
           'project[project_homepage_url]' => repo_url,
           'project[repo_url]' => repo_url
      assert_response :redirect
      follow_redirect!

      assert_response :success
      assert_template 'projects/edit'

      assert_select '#project_discussion_status_met[checked]'
    end
  end

  test 'logged-in user adds www.sendmail.com' do
    # Go to login_path to initialize the session
    get login_path
    log_in_as @user

    get '/projects/new'
    assert_response :success
    assert_template 'projects/new'

    project_url = 'https://www.sendmail.com/'

    VCR.use_cassette('sendmail') do
      post '/projects',
           'project[project_homepage_url]' => project_url,
           'project[repo_url]' => project_url
      assert_response :redirect
      follow_redirect!

      assert_response :success
      assert_template 'projects/edit'
      assert_select '#project_name[value=?]', 'sendmail'
    end
  end
end
