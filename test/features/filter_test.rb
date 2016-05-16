# frozen_string_literal: true
require 'test_helper'

class FilterTest < Capybara::Rails::TestCase
  scenario 'Can Filter Projects', js: true do
    visit '/projects'
    assert has_content? 'Add New Project'
    assert_equal 4, all('tbody tr').count
    assert has_content? '4 Projects'
    assert has_content? 'Pathfinder OS'
    assert has_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    select 'Passing', from: 'gteq'
    wait_for_url '/projects?gteq=100'
    assert_equal 1, all('tbody tr').count
    assert has_content? '1 Project'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_no_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    select 'In Progress (75% or more)', from: 'gteq'
    wait_for_url '/projects?gteq=75'
    assert_equal 2, all('tbody tr').count
    assert has_content? '2 Projects'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    fill_in 'q', with: 'unjustified'
    click_on 'Search'
    wait_for_url '/projects?gteq=75&q=unjustified'
    assert_equal 1, all('tbody tr').count
    assert has_content? '1 Project'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_no_content? 'Justified perfect project'

    fill_in 'q', with: ''
    click_on 'Search'
    wait_for_url '/projects?gteq=75'
    assert_equal 2, all('tbody tr').count
    assert has_content? '2 Projects'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    check 'lteq' # Click 'Exclude passing' checkbox
    wait_for_url '/projects?gteq=75&lteq=99'
    assert_equal 1, all('tbody tr').count
    assert has_content? '1 Project'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_no_content? 'Justified perfect project'

    # No UI to use status params
    visit '/projects?status=in_progress'
    wait_for_url '/projects?status=in_progress'
    assert_equal 3, all('tbody tr').count
    assert has_content? '3 Projects'
    assert has_content? 'Pathfinder OS'
    assert has_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_no_content? 'Justified perfect project'
  end
end
