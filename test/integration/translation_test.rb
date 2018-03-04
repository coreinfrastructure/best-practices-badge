# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class TranslationTest < ActionDispatch::IntegrationTest
  # setup do
  # end

  # Test typical pages in all supported locales.  This helps us detect
  # if there's a locale-specific problem, e.g., if we lack the necessary
  # keys for pluralization (Russian and Arabic have esp. complex requirements).
  test 'Can get common pages in all supported locales' do
    I18n.available_locales.each do |my_locale|
      get "/#{my_locale}/"
      assert_response :success

      get "/#{my_locale}"
      assert_redirected_to "/#{my_locale}/"

      get "/#{my_locale}/projects"
      assert_response :success

      get "/#{my_locale}/projects/#{projects(:one).id}"
      assert_response :success

      get "/#{my_locale}/users/#{users(:test_user).id}"
      assert_response :success

      get "/#{my_locale}/signup"
      assert_response :success

      get "/#{my_locale}/login"
      assert_response :success

      get "/#{my_locale}/criteria"
      assert_response :success

      # Skip testing /project_stats - it takes longer to generate and
      # is unlikely to be a problem.
    end
  end
end
