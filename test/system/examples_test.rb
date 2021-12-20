# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'application_system_test_case'

# Brief example of system tests; this is used to see if we can
# run system tests at all.
class ExamplesTest < ApplicationSystemTestCase
  test 'visiting the English home page' do
    visit '/en'
    assert_selector 'h2', text: 'OpenSSF Best Practices Badge Program'
  end
end
