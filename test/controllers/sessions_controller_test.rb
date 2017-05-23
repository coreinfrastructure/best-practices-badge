# frozen_string_literal: true

require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  setup do
    @user = users(:test_user_melissa)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should redirect logged in' do
    log_in_as(@user)
    get :new
    assert_not flash.empty?
    assert_redirected_to root_url
  end
end
