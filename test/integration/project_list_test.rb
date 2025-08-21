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

  test 'pagination works correctly on project list' do
    # Create additional projects to ensure pagination is triggered
    user = users(:test_user)
    original_count = Project.count
    projects_to_create = 32 - original_count # Ensure we have >30 projects

    if projects_to_create.positive?
      projects_to_create.times do |i|
        Project.create!(
          name: "Test Project #{i}",
          description: "Test description #{i}",
          user: user,
          repo_url: "https://github.com/test/project#{i}",
          homepage_url: "https://example.com/project#{i}"
        )
      end
    end

    get '/en/projects'
    assert_response :success

    # Now we should have pagination
    assert_select '.pagination', minimum: 1
    assert_select '.pagination a[href*="page=2"]', minimum: 1

    # Test that page 2 works
    get '/en/projects?page=2'
    assert_response :success
    # Should still have the main table structure
    assert_select 'table tbody tr', minimum: 1
  end
end
