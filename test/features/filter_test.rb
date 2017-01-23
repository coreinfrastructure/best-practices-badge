# frozen_string_literal: true
require 'capybara_feature_test'

class FilterTest < CapybaraFeatureTest
  # rubocop:disable Metrics/BlockLength
  scenario 'Can Filter Projects', js: true do
    visit '/projects'
    assert has_content? 'Add New Project'
    assert_equal 4, all('tbody tr').count
    assert has_content? '4 Projects'
    assert has_content? 'Pathfinder OS'
    assert has_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    # We would *like* to be able to use the select... wait_for_url pattern to
    # more accurately test the UI.  However, for security reasons
    # we use a Content Security Policy (CSP) that disables embedded JavaScript.
    # This CSP setting causes select...wait to fail in some environments.
    # We *want* to use CSP to harden the software, and we need to make
    # sure that our tests run while CSP is enabled.
    # So instead, we directly "visit" the pages; this doesn't test
    # the UI as thoroughly, but it has the advantage of actually working :-).
    #
    # select 'Passing', from: 'gteq'
    # wait_for_url '/projects?gteq=100'
    visit '/projects?gteq=100'
    assert_equal 1, all('tbody tr').count
    assert has_content? '1 Project'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_no_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    # select 'In Progress (75% or more)', from: 'gteq'
    # wait_for_url '/projects?gteq=75'
    visit '/projects?gteq=75'
    assert_equal 2, all('tbody tr').count
    assert has_content? '2 Projects'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    # fill_in 'q', with: 'unjustified'
    # click_on 'Search'
    # wait_for_url '/projects?gteq=75&q=unjustified'
    visit '/projects?gteq=75&q=unjustified'
    assert_equal 1, all('tbody tr').count
    assert has_content? '1 Project'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_no_content? 'Justified perfect project'

    # fill_in 'q', with: ''
    # click_on 'Search'
    # wait_for_url '/projects?gteq=75'
    visit '/projects?gteq=75'
    assert_equal 2, all('tbody tr').count
    assert has_content? '2 Projects'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_content? 'Justified perfect project'

    # check 'lteq' # Click 'Exclude passing' checkbox
    # wait_for_url '/projects?gteq=75&lteq=99'
    visit '/projects?gteq=75&lteq=99'
    assert_equal 1, all('tbody tr').count
    assert has_content? '1 Project'
    assert has_no_content? 'Pathfinder OS'
    assert has_no_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_no_content? 'Justified perfect project'

    # No UI to use status params
    visit '/projects?status=in_progress'
    # wait_for_url '/projects?status=in_progress'
    assert_equal 3, all('tbody tr').count
    assert has_content? '3 Projects'
    assert has_content? 'Pathfinder OS'
    assert has_content? 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Unjustified perfect project'
    assert has_no_content? 'Justified perfect project'
  end
  # rubocop:enable Metrics/BlockLength
end
