require 'test_helper'

class CanFilterTest < Capybara::Rails::TestCase
  scenario 'Can Filter Projects', js: true do
    visit '/projects'
    assert_equal 4, all('tbody tr').count
    assert has_content? 'Pathfinder OS'
    assert has_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    select 'Passing', from: 'status'
    wait_for_url '/projects?status=passing'
    assert_equal 1, all('tbody tr').count
    refute has_content? 'Pathfinder OS'
    refute has_content? 'Mars Ascent Vehicle (MAV)'
    refute has_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'
    p 'Got here'

    select 'Failing', from: 'status'
    wait_for_url '/projects?status=failing'
    assert_equal 1, all('tbody tr').count
    refute has_content? 'Pathfinder OS'
    refute has_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    refute has_content? 'Justified perfect project'

    select 'In Progress', from: 'status'
    wait_for_url '/projects?status=in_progress'
    assert_equal 2, all('tbody tr').count
    assert has_content? 'Pathfinder OS'
    assert has_content? 'Mars Ascent Vehicle (MAV)'
    refute has_content? 'Unjustified perfect project'
    refute has_content? 'Justified perfect project'

    fill_in 'q', with: 'mars'
    click_on 'Search'
    wait_for_url '/projects?q=mars&status=in_progress'
    assert_equal 1, all('tbody tr').count
    refute has_content? 'Pathfinder OS'
    assert has_content? 'Mars Ascent Vehicle (MAV)'
    refute has_content? 'Unjustified perfect project'
    refute has_content? 'Justified perfect project'

    fill_in 'q', with: ''
    click_on 'Search'
    wait_for_url '/projects?status=in_progress'
    assert_equal 2, all('tbody tr').count
    assert has_content? 'Pathfinder OS'
    assert has_content? 'Mars Ascent Vehicle (MAV)'
    refute has_content? 'Unjustified perfect project'
    refute has_content? 'Justified perfect project'
  end
end
