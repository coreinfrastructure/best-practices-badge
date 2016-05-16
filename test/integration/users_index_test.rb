# frozen_string_literal: true
require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @admin_user = users(:admin_user)
  end

  test 'unsuccessful index' do
    log_in_as(@user)
    get users_path
    assert_redirected_to root_url
  end

  test 'successful index' do
    log_in_as(@admin_user)
    get users_path
    assert_response :success
    assert_template 'index'
  end
end
