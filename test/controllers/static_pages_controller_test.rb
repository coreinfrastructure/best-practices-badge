# frozen_string_literal: true

require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase
  test 'should get home' do
    get :home
    assert_response :success
    assert_template 'home.en'

    get :home, params: { locale: 'fr' }
    assert_response :success
    assert_template 'home.fr'

    get :home, params: { locale: 'zh-CN' }
    assert_response :success
    assert_template 'home.zh-CN'
  end

  test 'should get background' do
    get :background
    assert_response :success
  end

  test 'should get criteria' do
    get :criteria
    assert_response :success

    get :criteria, params: { locale: 'fr' }
    assert_response :success
    assert_template 'criteria.fr'

    get :criteria, params: { locale: 'zh-CN' }
    assert_response :success
    assert_template 'criteria.zh-CN'
  end
end
