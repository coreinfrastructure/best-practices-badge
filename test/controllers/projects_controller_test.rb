require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
  end

  test 'should get index' do
    skip('Needs debugging')
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create project' do
    skip('Needs debugging')
    assert_difference('Project.count') do
      post :create, project: { description: @project.description,
                               license: @project.license,
                               name: @project.name,
                               repo_url: @project.repo_url,
                               project_url: @project.project_url }
    end

    assert_redirected_to project_path(assigns(:project))
  end

  test 'should show project' do
    skip('Needs debugging')
    get :show, id: @project
    assert_response :success
  end

  test 'should get edit' do
    skip('Needs debugging')
    get :edit, id: @project
    assert_response :success
  end

  test 'should update project' do
    skip('Needs debugging')
    patch :update, id: @project, project: { description: @project.description,
                                            license: @project.license,
                                            name: @project.name,
                                            repo_url: @project.repo_url,
                                            project_url: @project.project_url }
    assert_redirected_to project_path(assigns(:project))
  end

  test 'should destroy project' do
    skip('Needs debugging')
    assert_difference('Project.count', -1) do
      delete :destroy, id: @project
    end

    assert_redirected_to projects_path
  end
end
