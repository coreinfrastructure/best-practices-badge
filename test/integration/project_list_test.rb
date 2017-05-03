# frozen_string_literal: true

require 'test_helper'

class ProjectListTest < ActionDispatch::IntegrationTest
  setup do
    # @user = users(:test_user)
  end

  test 'get project list and sort by name' do
    get '/projects'
    assert_response :success
    assert_select 'table>tbody>tr:first-child>td:nth-child(2)'.dup,
                  'Pathfinder OS'

    get '/projects?sort=name'
    assert_response :success
    assert_select 'table>tbody>tr:first-child>td:nth-child(2)'.dup,
                  'Justified perfect project'

    get '/projects?sort=name&sort_direction=desc'
    assert_response :success
    assert_select 'table>tbody>tr:first-child>td:nth-child(2)'.dup,
                  'Unjustified perfect project'
  end
end
