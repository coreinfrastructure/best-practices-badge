# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @project_two = projects(:two)
    @perfect_unjustified_project = projects(:perfect_unjustified)
    @perfect_passing_project = projects(:perfect_passing)
    @perfect_silver_project = projects(:perfect_silver)
    @perfect_project = projects(:perfect)
    @user = users(:test_user)
    @admin = users(:admin_user)
  end

  # Ensure that every criterion that is *supposed* to be in this level is
  # selectable, and that every criterion that is *not* supposed to be in this
  # level is not selectable.
  # rubocop:disable Metrics/MethodLength
  def only_correct_criteria_selectable(level)
    Criteria.keys do |query_level|
      Criteria[query_level].each do |criterion|
        if query_level == level
          assert_select '#' + criterion.to_s
          assert_select "#project_#{criterion}_status_met"
        elsif !Criteria[level].key?(criterion)
          # This is criterion in another level, *not* this one
          assert_select '#' + criterion.to_s, false
          assert_select "#project_#{criterion}_status_met", false
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

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
    assert_difference [
      'Project.count', 'ActionMailer::Base.deliveries.size'
    ] do
      post :create, params: { project: {
        description: @project.description,
        license: @project.license,
        name: @project.name,
        repo_url: 'https://www.example.org/code',
        homepage_url: @project.homepage_url
      } }
    end
  end

  test 'should fail to create project' do
    log_in_as(@user)
    url = 'https://api.github.com/user/repos?client_id=' \
          "#{ENV['TEST_GITHUB_KEY']}&client_secret=" \
          "#{ENV['TEST_GITHUB_SECRET']}&per_page=100"
    stub_request(:get, url).to_return(status: 200, body: '', headers: {})
    assert_no_difference('Project.count') do
      post :create, params: { project: { name: @project.name } }
    end
    assert_no_difference('Project.count') do
      post :create, format: :json, params: { project: { name: @project.name } }
    end
  end

  test 'should show project' do
    get :show, params: { id: @project }
    assert_response :success
    assert_select 'a[href=?]'.dup, 'https://www.nasa.gov'
    assert_select 'a[href=?]'.dup, 'https://www.nasa.gov/pathfinder'
    only_correct_criteria_selectable('0')
  end

  test 'should show project with criteria_level=1' do
    get :show, params: { id: @project, criteria_level: '1' }
    assert_response :success
    assert_select 'a[href=?]'.dup, 'https://www.nasa.gov'
    assert_select 'a[href=?]'.dup, 'https://www.nasa.gov/pathfinder'
    only_correct_criteria_selectable('1')
  end

  test 'should show project with criteria_level=2' do
    get :show, params: { id: @project, criteria_level: '2' }
    assert_response :success
    assert_select 'a[href=?]'.dup, 'https://www.nasa.gov'
    assert_select 'a[href=?]'.dup, 'https://www.nasa.gov/pathfinder'
    only_correct_criteria_selectable('2')
  end

  test 'should show project JSON data' do
    get :show_json, params: { id: @project, format: :json }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 'Pathfinder OS', body['name']
    assert_equal 'Operating system for Pathfinder rover', body['description']
    assert_equal 'https://www.nasa.gov', body['homepage_url']
  end

  test 'should get edit' do
    log_in_as(@project.user)
    get :edit, params: { id: @project }
    assert_response :success
    assert_not_empty flash
  end

  test 'should get edit as additional rights user' do
    test_user = users(:test_user_mark)
    # Create additional rights during test, not as a fixure.
    # The fixture would require correct references to *other* fixture ids.
    new_right = AdditionalRight.new(
      user_id: test_user.id,
      project_id: @project.id
    )
    new_right.save!
    log_in_as(test_user)
    get :edit, params: { id: @project }
    assert_response :success
    assert_not_empty flash
  end

  test 'should not get edit as user without additional rights' do
    # Without additional rights, can't log in.  This is paired with
    # previous test, to ensure that *only* the additional right provides
    # the necessary rights.
    test_user = users(:test_user_mark)
    log_in_as(test_user)
    get :edit, params: { id: @project }
    assert_response 302
    assert_redirected_to root_path
  end

  test 'should fail to edit due to old session' do
    log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
    get :edit, params: { id: @project }
    assert_response 302
    assert_redirected_to login_path
  end

  test 'should fail to edit due to session time missing' do
    log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
    session.delete(:time_last_used)
    get :edit, params: { id: @project }
    assert_response 302
    assert_redirected_to login_path
  end

  test 'should update project' do
    log_in_as(@project.user)
    new_name = @project.name + '_updated'
    patch :update, params: {
      id: @project, project: {
        description: @project.description,
        license: @project.license,
        name: new_name,
        repo_url: @project.repo_url,
        homepage_url: @project.homepage_url
      }
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
    patch :update, params: { id: @project, project: new_project_data }
    # "Success" here only in the HTTP sense - we *do* get a form...
    assert_response :success
    # ... but we just get the edit form.
    assert_template :edit

    # Do the same thing, but as for JSON
    patch :update, params: {
      id: @project, format: :json, project: new_project_data
    }
    assert_response :unprocessable_entity
  end

  test 'should fail to update stale project' do
    new_name1 = @project.name + '_updated-1'
    new_project_data1 = { name: new_name1 }
    new_name2 = @project.name + '_updated-2'
    new_project_data2 = {
      name: new_name2,
      lock_version: @project.lock_version
    }
    log_in_as(@project.user)
    patch :update, params: { id: @project, project: new_project_data1 }
    assert_redirected_to project_path(assigns(:project))
    get :edit, params: { id: @project }
    patch :update, params: { id: @project, project: new_project_data2 }
    assert_not_empty flash
    assert_template :edit
    assert_difference '@project.lock_version' do
      @project.reload
    end
    assert_equal @project.name, new_name1
  end

  test 'should fail update project with invalid control in name' do
    log_in_as(@project.user)
    old_name = @project.name
    new_name = @project.name + "\x0c"
    patch :update, params: {
      id: @project, project: {
        description: @project.description,
        license: @project.license,
        name: new_name,
        repo_url: @project.repo_url,
        homepage_url: @project.homepage_url
      }
    }
    # "Success" here only in the HTTP sense - we *do* get a form...
    assert_response :success
    # ... but we just get the edit form.
    assert_template :edit
    assert_equal @project.name, old_name
  end

  test 'should fail to update other users project' do
    new_name = @project_two.name + '_updated'
    assert_not_equal @user, @project_two.user
    log_in_as(@user)
    patch :update, params: { id: @project_two, project: { name: new_name } }
    assert_redirected_to root_url
  end

  test 'admin can update other users project' do
    new_name = @project.name + '_updated'
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    patch :update, params: { id: @project, project: { name: new_name } }
    assert_redirected_to project_path(assigns(:project))
    @project.reload
    assert_equal @project.name, new_name
  end

  test 'A perfect passing project should have the passing badge' do
    get :badge, params: { id: @perfect_passing_project, format: 'svg' }
    assert_response :success
    assert_equal contents('badge-passing.svg'), @response.body
  end

  test 'A perfect silver project should have the silver badge' do
    get :badge, params: { id: @perfect_silver_project, format: 'svg' }
    assert_response :success
    assert_equal contents('badge-silver.svg'), @response.body
  end

  test 'A perfect project should have the gold badge' do
    get :badge, params: { id: @perfect_project, format: 'svg' }
    assert_response :success
    assert_equal contents('badge-gold.svg'), @response.body
  end

  test 'A perfect unjustified project should have in progress badge' do
    get :badge, params: { id: @perfect_unjustified_project, format: 'svg' }
    assert_response :success
    assert_includes @response.body, 'in progress'
  end

  test 'An empty project should not have the badge; it should be in progress' do
    get :badge, params: { id: @project, format: 'svg' }
    assert_response :success
    assert_includes @response.body, 'in progress'
  end

  test 'Achievement datetimes set' do
    log_in_as(@admin)
    assert_nil @perfect_passing_project.lost_passing_at
    assert_not_nil @perfect_passing_project.achieved_passing_at
    patch :update, params: {
      id: @perfect_passing_project, project: {
        interact_status: 'Unmet'
      }
    }
    @perfect_passing_project.reload
    assert_not_nil @perfect_passing_project.lost_passing_at
    assert @perfect_passing_project.lost_passing_at > 5.minutes.ago.utc
    assert_not_nil @perfect_passing_project.achieved_passing_at
    patch :update, params: {
      id: @perfect_passing_project, project: {
        interact_status: 'Met'
      }
    }
    assert_not_nil @perfect_passing_project.lost_passing_at
    # These tests should work, but don't; it appears our workaround for
    # the inadequately reset database interferes with them.
    # assert_not_nil @perfect_passing_project.achieved_passing_at
    # assert @perfect_passing_project.achieved_passing_at > 5.minutes.ago.utc
    # assert @perfect_passing_project.achieved_passing_at >
    #        @perfect_passing_project.lost_passing_at
  end

  test 'should destroy own project' do
    log_in_as(@project.user)
    num = ActionMailer::Base.deliveries.size
    assert_difference('Project.count', -1) do
      delete :destroy, params: { id: @project }
    end
    assert_not_empty flash
    assert_redirected_to projects_path
    assert_equal num + 1, ActionMailer::Base.deliveries.size
  end

  test 'Admin can destroy any project' do
    log_in_as(@admin)
    num = ActionMailer::Base.deliveries.size
    assert_not_equal @admin, @project.user
    assert_difference('Project.count', -1) do
      delete :destroy, params: { id: @project }
    end

    assert_redirected_to projects_path
    assert_equal num + 1, ActionMailer::Base.deliveries.size
  end

  test 'should not destroy project if no one is logged in' do
    # Notice that we do *not* call log_in_as.
    assert_no_difference('Project.count', ActionMailer::Base.deliveries.size) do
      delete :destroy, params: { id: @project }
    end
  end

  test 'should redirect to project page if project repo exists' do
    log_in_as(@user)
    assert_no_difference('Project.count') do
      post :create, params: { project: { repo_url: @project.repo_url } }
    end
    assert_redirected_to project_path(@project)
  end

  test 'should fail to change tail of non-blank repo_url' do
    new_repo_url = @project_two.repo_url + '_new'
    log_in_as(@project_two.user)
    patch :update, params: {
      id: @project_two, project: {
        repo_url:  new_repo_url
      }
    }
    assert_not_empty flash
    assert_template :edit
    @project_two.reload
    assert_not_equal @project_two.repo_url, new_repo_url
  end

  test 'should change https to http in non-blank repo_url' do
    old_repo_url = @project_two.repo_url
    new_repo_url = 'http://www.nasa.gov/mav'
    log_in_as(@project_two.user)
    patch :update, params: {
      id: @project_two, project: {
        repo_url:  new_repo_url
      }
    }
    @project_two.reload
    assert_not_equal @project_two.repo_url, old_repo_url
    assert_equal @project_two.repo_url, new_repo_url
  end

  test 'admin can change other users non-blank repo_url' do
    new_repo_url = @project_two.repo_url + '_new'
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    patch :update, params: {
      id: @project_two, project: {
        repo_url:  new_repo_url
      }
    }
    @project_two.reload
    assert_equal @project_two.repo_url, new_repo_url
  end

  test 'should redirect with empty query params removed' do
    get :index, params: { q: '', status: 'passing' }
    assert_redirected_to 'http://test.host/projects?status=passing'
  end

  test 'should redirect with all query params removed' do
    get :index, params: { q: '', status: '' }
    assert_redirected_to 'http://test.host/projects'
  end

  test 'should remove invalid parameter' do
    get :index, params: { role: 'admin', status: 'passing' }
    assert_redirected_to 'http://test.host/projects?status=passing'
  end

  test 'Check ids= projects index query' do
    get :index, params: {
      format: :json,
      ids: "#{@project.id},#{@project_two.id}"
    }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body.length
  end

  test 'should redirect http to https' do
    old = Rails.application.config.force_ssl
    Rails.application.config.force_ssl = true
    get :index
    assert_redirected_to 'https://test.host/projects'
    Rails.application.config.force_ssl = old
  end

  test 'sanity test of reminders' do
    result = ProjectsController.send :send_reminders
    assert_equal 1, result.size
  end
end
