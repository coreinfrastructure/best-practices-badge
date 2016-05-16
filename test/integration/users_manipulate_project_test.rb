# frozen_string_literal: true
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
           'project[homepage_url]' => repo_url,
           'project[repo_url]' => repo_url
      assert_response :redirect
      follow_redirect!

      assert_response :success
      assert_template 'projects/edit'

      # Check to ensure that the form includes all the criteria, but only once.
      # This could fail if the view incorrectly omits or duplicates one.
      Criteria.each do |criterion|
        assert_select "##{criterion}" # Check for existence
        assert_select "##{criterion}" do |elements|
          assert_equal 1, elements.count # Check for duplication
        end
      end

      # Ensure that all id's are unique.
      all_name_id = Set.new
      my_result_id = css_select('[id]') # my_result[0]['id']
      my_result_id.each do |e|
        assert_not_includes all_name_id, e['id']
        all_name_id.add e['id']
      end

      # Check that major sections/classes are included in the HTML
      # TODO: Add back assert_select for CSS classes
      assert_select 'header'
      # assert_select '.navbar'
      assert_select 'footer'
      # assert_select '.footer'
      # assert_select '.container'

      # Check if Fastly logo is included.  We can't easily check the img src
      # value, because the image asset has a fingerprint, but we can detect
      # the 'alt' value easily, and we want to provide an alt value anyway.
      assert_select "img[alt='Fastly logo']"

      # This ensures that all rows are in containers - except that
      # this currently isn't true:
      # assert_select '#badge-progress' # Ensure we have progress bar area.
      # css_select('.row').each do |e|
      #   assert_includes ['container', 'container-fluid'], e.parent['class']
      # end

      # Check that returned settings are correct.
      # Note: You can use byebug... css_select to interactively check things.
      assert_select '#project_name[value=?]'.dup,
                    'Core Infrastructure Initiative Best Practices Badge'
      assert_select '#project_discussion_status_met[checked]'
      assert_select '#project_contribution_status_met[checked]'
      assert_select '#project_floss_license_status_met[checked]'
      assert_select '#project_floss_license_osi_status_met[checked]'
      assert_select '#project_license_location_status_met[checked]'
      assert_select '#project_repo_public_status_met[checked]'
      assert_select '#project_repo_track_status_met[checked]'
      assert_select '#project_repo_distributed_status_met[checked]'
      assert_select '#project_release_notes_status_met[checked]'
      assert_select '#project_build_status_met[checked]'
      assert_select '#project_build_common_tools_status_met[checked]'
      assert_select '#project_contribution_status_met[checked]'
      assert_select '#project_sites_https_status_met[checked]'

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
           'project[homepage_url]' => repo_url,
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
           'project[homepage_url]' => project_url,
           'project[repo_url]' => project_url
      assert_response :redirect
      follow_redirect!

      assert_response :success
      assert_template 'projects/edit'
      assert_select '#project_name[value=?]'.dup, 'sendmail'
    end
  end
end
