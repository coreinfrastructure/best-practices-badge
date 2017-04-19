# frozen_string_literal: true

require 'test_helper'

class NoPageTest < ActionDispatch::IntegrationTest
  test 'No such page returns 404' do
    get '/wp-login.php'
    assert_response :missing
    assert_template 'static_pages/error_404'
  end
end
