# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'capybara_feature_test'

class JavascriptTest < CapybaraFeatureTest
  setup do
    @project_passing = projects(:perfect_passing)
  end

  scenario 'Check show/hide Met on show for passing', js: true do
    visit project_path(@project_passing, locale: :en)
    wait_for_jquery
    find('#toggle-expand-all-panels').click
    wait_for_jquery
    assert_selector(:css, '#discussion')
    assert_selector(:css, '#english')
    assert_selector(:css, '#contribution')
    assert_selector(:css, '#repo_public')
    assert_selector(:css, '#report_process')
    find('#toggle-hide-metna-criteria').click
    wait_for_jquery
    refute_selector(:css, '#discussion')
    refute_selector(:css, '#english')
    refute_selector(:css, '#contribution')
    refute_selector(:css, '#repo_public')
    refute_selector(:css, '#report_process')
  end
  scenario 'Check show/hide Met works for silver', js: true do
    visit project_path(@project_passing, locale: :en, criterion_level: '1')
    wait_for_jquery
    find('#toggle-expand-all-panels').click
    wait_for_jquery
    assert_selector(:css, '#contribution_requirements')
    assert_selector(:css, '#report_tracker')
    assert_selector(:css, '#warnings')
    find('#toggle-hide-metna-criteria').click
    wait_for_jquery
    refute_selector(:css, '#contribution_requirements')
    refute_selector(:css, '#report_tracker')
    refute_selector(:css, '#warnings')
  end
end
