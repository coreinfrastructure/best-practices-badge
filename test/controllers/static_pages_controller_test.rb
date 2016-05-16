# frozen_string_literal: true
require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase
  test 'should get home' do
    get :home
    assert_response :success
  end

  test 'should get background' do
    get :background
    assert_response :success
  end

  test 'should get criteria' do
    get :criteria
    assert_response :success
  end
end
