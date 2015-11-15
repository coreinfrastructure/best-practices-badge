require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @perfect_project = projects(:perfect)
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
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    assert_difference('Project.count') do
      post :create, project: {
        description: @project.description,
        license: @project.license,
        name: @project.name,
        repo_url: @project.repo_url,
        project_homepage_url: @project.project_homepage_url
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
  end

  test 'should get edit' do
    log_in_as(@project.user)
    get :edit, id: @project
    assert_response :success
  end

  test 'should update project' do
    log_in_as(@project.user)
    patch :update, id: @project, project: {
      description: @project.description,
      license: @project.license,
      name: @project.name,
      repo_url: @project.repo_url,
      project_homepage_url: @project.project_homepage_url
    }
    assert_redirected_to project_path(assigns(:project))
  end

  test 'should fail to update project' do
    new_project_data = {
      description: '',
      license: '',
      name: '',
      repo_url: '',
      project_homepage_url: ''
    }
    log_in_as(@project.user)
    patch :update, id: @project, project: new_project_data
    assert_response :success
    assert_template :edit

    # Do the same thing, but as for JSON
    patch :update, id: @project, format: :json, project: new_project_data
    assert_response :unprocessable_entity
  end

  test 'A perfect project should have the badge' do
    get :badge, id: @perfect_project, format: 'svg'
    assert_response :success
    assert_includes @response.body, 'passing'
  end

  test 'An empty project should not have the badge' do
    get :badge, id: @project, format: 'svg'
    assert_response :success
    assert_includes @response.body, 'failing'
  end

  test 'should destroy project' do
    log_in_as(@project.user)
    assert_difference('Project.count', -1) do
      delete :destroy, id: @project
    end

    assert_redirected_to projects_path
  end
end
