# frozen_string_literal: true

require 'test_helper'

class ProjectStatsControllerTest < ActionController::TestCase
  setup do
    @project_stat = project_stats(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:project_stats)
  end

  test 'should get index, CSV format' do
    get :index, format: :csv
    assert_response :success
    contents = CSV.parse(response.body, headers: true)
    assert_equal 'id', contents.headers[0]
    assert_equal %w(
      id created_at percent_ge_0
      percent_ge_25 percent_ge_50 percent_ge_75
      percent_ge_90 percent_ge_100
      created_since_yesterday updated_since_yesterday
      updated_at reminders_sent
      reactivated_after_reminder active_projects
      active_in_progress projects_edited
      active_edited_projects active_edited_in_progress
    ), contents.headers
    assert_equal 2, contents.size
    assert_equal '13', contents[0]['percent_ge_50']
    assert_equal '20', contents[0]['percent_ge_0']
    assert_equal '19', contents[1]['percent_ge_0']
  end

  test 'should get new' do
    assert_raises Object do
      get :new
    end
  end

  test 'should NOT create project_stat' do
    assert_raises AbstractController::ActionNotFound do
      post :create, params: { project_stat:
        {
          percent_ge_0: @project_stat.percent_ge_0,
          percent_ge_25: @project_stat.percent_ge_25,
          percent_ge_50: @project_stat.percent_ge_50,
          percent_ge_75: @project_stat.percent_ge_75,
          percent_ge_90: @project_stat.percent_ge_90,
          percent_ge_100: @project_stat.percent_ge_100,
          created_since_yesterday: @project_stat.created_since_yesterday,
          updated_since_yesterday: @project_stat.updated_since_yesterday
        } }
    end
  end

  test 'should show project_stat' do
    get :show, params: { id: @project_stat }
    assert_response :success
  end

  test 'should NOT get edit' do
    assert_raises Object do
      get :edit, params: { id: @project_stat }
    end
  end

  test 'should NOT update project_stat' do
    assert_raises AbstractController::ActionNotFound do
      patch :update, params: {
        id: @project_stat,
        project_stat:
              {
                percent_ge_0: @project_stat.percent_ge_0,
                percent_ge_25: @project_stat.percent_ge_25,
                percent_ge_50: @project_stat.percent_ge_50,
                percent_ge_75: @project_stat.percent_ge_75,
                percent_ge_90: @project_stat.percent_ge_90,
                percent_ge_100: @project_stat.percent_ge_100,
                created_since_yesterday: @project_stat.created_since_yesterday,
                updated_since_yesterday: @project_stat.updated_since_yesterday
              }
      }
    end
  end

  test 'should NOT destroy project_stat' do
    assert_raises AbstractController::ActionNotFound do
      delete :destroy, params: { id: @project_stat }
    end
  end
end
