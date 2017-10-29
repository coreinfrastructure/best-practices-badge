# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase
  test 'should get home' do
    get :home
    assert_response :success
    assert_template 'home'
  end

  test 'should get cookie page' do
    get :cookies
    assert_response :success
    assert_includes @response.body, 'About Cookies'
    assert_includes @response.body, 'small data files'
  end

  test 'should get robots.txt' do
    get :robots, format: :text
    assert_response :success
    assert_template 'robots'
  end

  test 'should get criteria' do
    get :criteria
    assert_response :success
    assert_template 'criteria'

    get :criteria, params: { locale: 'fr' }
    assert_response :success
    assert_template 'criteria'

    get :criteria, params: { locale: 'zh-CN' }
    assert_response :success
    assert_template 'criteria'
  end
end
