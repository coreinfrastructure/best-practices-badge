require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @user = users(:test_user)
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
    assert_difference('Project.count') do
      post :create, project: { description: @project.description,
                               license: @project.license,
                               name: @project.name,
                               repo_url: @project.repo_url,
                               project_url: @project.project_url }
    end
  end

  test 'should show project' do
    get :show, id: @project
    assert_response :success
  end

  test 'should get edit' do
    log_in_as(@project.user)
    get :edit, id: @project
    assert_response :success
  end

  test 'should update project' do
    log_in_as(@project.user)
    patch :update, id: @project, project: { description: @project.description,
                                            license: @project.license,
                                            name: @project.name,
                                            repo_url: @project.repo_url,
                                            project_url: @project.project_url }
    assert_redirected_to project_path(assigns(:project))
  end

  test 'should destroy project' do
    log_in_as(@project.user)
    assert_difference('Project.count', -1) do
      delete :destroy, id: @project
    end

    assert_redirected_to projects_path
  end
end
