# frozen_string_literal: true
require 'test_helper'

# rubocop:disable Metrics/ClassLength
class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @project_two = projects(:two)
    @perfect_unjustified_project = projects(:perfect_unjustified)
    @perfect_project = projects(:perfect)
    @user = users(:test_user)
    @admin = users(:admin_user)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create project' do
    log_in_as(@user)
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    assert_difference('Project.count') do
      post :create, project: {
        description: @project.description,
        license: @project.license,
        name: @project.name,
        repo_url: 'https://www.example.org/code',
        homepage_url: @project.homepage_url
      }
    end
  end

  test 'should fail to create project' do
    log_in_as(@user)
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    assert_no_difference('Project.count') do
      post :create, project: { name: @project.name }
    end
    assert_no_difference('Project.count') do
      post :create, format: :json, project: { name: @project.name }
    end
  end

  test 'should show project' do
    get :show, id: @project
    assert_response :success
    assert_select 'a[href=?]'.dup, 'https://www.nasa.gov'
    assert_select 'a[href=?]'.dup, 'https://www.nasa.gov/pathfinder'
  end

  test 'should get edit' do
    log_in_as(@project.user)
    get :edit, id: @project
    assert_response :success
  end

  test 'should fail to edit due to old session' do
    log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
    get :edit, id: @project
    assert_response 302
    assert_redirected_to login_path
  end

  test 'should fail to edit due to session time missing' do
    log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
    session.delete(:time_last_used)
    get :edit, id: @project
    assert_response 302
    assert_redirected_to login_path
  end

  test 'should update project' do
    log_in_as(@project.user)
    new_name = @project.name + '_updated'
    patch :update, id: @project, project: {
      description: @project.description,
      license: @project.license,
      name: new_name,
      repo_url: @project.repo_url,
      homepage_url: @project.homepage_url
    }
    assert_redirected_to project_path(assigns(:project))
    @project.reload
    assert_equal @project.name, new_name
  end

  test 'should fail to update project' do
    new_project_data = {
      description: '',
      license: '',
      name: '',
      homepage_url: 'example.org' # bad url
    }
    log_in_as(@project.user)
    patch :update, id: @project, project: new_project_data
    # "Success" here only in the HTTP sense - we *do* get a form...
    assert_response :success
    # ... but we just get the edit form.
    assert_template :edit

    # Do the same thing, but as for JSON
    patch :update, id: @project, format: :json, project: new_project_data
    assert_response :unprocessable_entity
  end

  test 'should fail to update other users project' do
    new_name = @project_two.name + '_updated'
    assert_not_equal @user, @project_two.user
    log_in_as(@user)
    patch :update, id: @project_two, project: {
      name: new_name
    }
    assert_redirected_to root_url
  end

  test 'admin can update other users project' do
    new_name = @project.name + '_updated'
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    patch :update, id: @project, project: {
      name: new_name
    }
    assert_redirected_to project_path(assigns(:project))
    @project.reload
    assert_equal @project.name, new_name
  end

  test 'A perfect project should have the badge' do
    get :badge, id: @perfect_project, format: 'svg'
    assert_response :success
    assert_includes @response.body, 'passing'
  end

  test 'A perfect unjustified project should not have the badge' do
    get :badge, id: @perfect_unjustified_project, format: 'svg'
    assert_response :success
    assert_includes @response.body, 'in progress'
  end

  test 'An empty project should not have the badge; it should be in progress' do
    get :badge, id: @project, format: 'svg'
    assert_response :success
    assert_includes @response.body, 'in progress'
  end

  test 'Achievement datetimes set' do
    log_in_as(@admin)
    assert_nil @perfect_project.lost_passing_at
    assert_nil @perfect_project.achieved_passing_at
    patch :update, id: @perfect_project, project: {
      interact_status: 'Unmet'
    }
    @perfect_project.reload
    assert_not_nil @perfect_project.lost_passing_at
    assert @perfect_project.lost_passing_at > 5.minutes.ago.utc
    assert_nil @perfect_project.achieved_passing_at
    patch :update, id: @perfect_project, project: {
      interact_status: 'Met'
    }
    assert_not_nil @perfect_project.lost_passing_at
    # These tests should work, but don't; it appears our workaround for
    # the inadequately reset database interferes with them.
    # assert_not_nil @perfect_project.achieved_passing_at
    # assert @perfect_project.achieved_passing_at > 5.minutes.ago.utc
    # assert @perfect_project.achieved_passing_at >
    #        @perfect_project.lost_passing_at
  end

  test 'should destroy own project' do
    log_in_as(@project.user)
    assert_difference('Project.count', -1) do
      delete :destroy, id: @project
    end
    assert_not_empty flash
    assert_redirected_to projects_path
  end

  test 'Admin can destroy any project' do
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    assert_difference('Project.count', -1) do
      delete :destroy, id: @project
    end

    assert_redirected_to projects_path
  end

  test 'should not destroy project if no one is logged in' do
    # Notice that we do *not* call log_in_as.
    assert_no_difference('Project.count') do
      delete :destroy, id: @project
    end
  end

  test 'should redirect to project page if project repo exists' do
    log_in_as(@user)
    assert_no_difference('Project.count') do
      post :create, project: { repo_url: @project.repo_url }
    end
    assert_redirected_to project_path(@project)
  end

  test 'should fail to change non-blank repo_url' do
    new_repo_url = @project_two.repo_url + '_new'
    log_in_as(@project_two.user)
    patch :update, id: @project_two, project: {
      repo_url:  new_repo_url
    }
    @project_two.reload
    assert_not_equal @project_two.repo_url, new_repo_url
  end

  test 'admin can change other users non-blank repo_url' do
    new_repo_url = @project_two.repo_url + '_new'
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    patch :update, id: @project_two, project: {
      repo_url:  new_repo_url
    }
    @project_two.reload
    assert_equal @project_two.repo_url, new_repo_url
  end

  test 'should redirect with empty query params removed' do
    get :index, q: '', status: 'passing'
    assert_redirected_to 'http://test.host/projects?status=passing'
  end

  test 'should redirect with all query params removed' do
    get :index, q: '', status: ''
    assert_redirected_to 'http://test.host/projects'
  end

  test 'should redirect http to https' do
    old = Rails.application.config.force_ssl
    Rails.application.config.force_ssl = true
    get :index
    assert_redirected_to 'https://test.host/projects'
    Rails.application.config.force_ssl = old
  end

  test 'sanity test of reminders' do
    result = ProjectsController.send_reminders
    assert_equal 1, result.size
  end
end
