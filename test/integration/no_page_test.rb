# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class NoPageTest < ActionDispatch::IntegrationTest
  test 'No such page returns 404' do
    get '/wp-login.php'
    assert_response :missing
    assert_template 'static_pages/error_404'
  end
end
