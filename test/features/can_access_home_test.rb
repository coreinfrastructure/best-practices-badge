require 'test_helper'

class CanAccessHomeTest < Capybara::Rails::TestCase
  test 'sanity' do
    visit root_path
    assert_content page, 'CII Best Practices Badge Program'
  end

  test 'New Project link' do
    visit root_path
    click_link 'Get Your Badge Now!'
  end
end
