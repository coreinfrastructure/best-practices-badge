# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class ProjectListTest < ActionDispatch::IntegrationTest
  setup do
    # @user = users(:test_user)
  end

  test 'get project list and sort by name' do
    get '/en/projects'
    assert_response :success
    assert_select(
      +'table>tbody>tr:first-child>td:nth-child(2)',
      'Pathfinder OS'
    )

    get '/en/projects?sort=name'
    assert_response :success
    assert_select(
      +'table>tbody>tr:first-child>td:nth-child(2)',
      'Another Ascent Vehicle (AAV)'
    )

    get '/en/projects?sort=name&sort_direction=desc'
    assert_response :success
    assert_select(
      +'table>tbody>tr:first-child>td:nth-child(2)',
      'Unjustified perfect project'
    )
  end
end
