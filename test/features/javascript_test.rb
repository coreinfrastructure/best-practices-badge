# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'capybara_feature_test'

class LoginTest < CapybaraFeatureTest
  setup do
    @project = projects(:perfect_passing)
  end

  scenario 'Check show/hide Met on show for passing', js: true do
    visit project_path(@project, locale: nil)
    wait_for_jquery
    find('#toggle-expand-all-panels').click
    wait_for_jquery
    assert has_content? 'discussion'
    assert has_content? 'english'
    assert has_content? 'contribution'
    assert has_content? 'repo_public'
    assert has_content? 'report_process'
    find('#toggle-hide-metna-criteria').click
    wait_for_jquery
    refute has_content? 'discussion'
    refute has_content? 'english'
    refute has_content? 'contribution'
    refute has_content? 'repo_public'
    refute has_content? 'report_process'
  end
  scenario 'Check show/hide Met works for silver', js: true do
    visit project_path(@project, locale: nil)
    wait_for_jquery
    find('#toggle-expand-all-panels').click
    wait_for_jquery
    assert has_content? 'contribution_requirements'
    assert has_content? 'report_tracker'
    assert has_content? 'installation_common'
    find('#toggle-hide-metna-criteria').click
    wait_for_jquery
    refute has_content? 'contribution_requirements'
    refute has_content? 'report_tracker'
    refute has_content? 'installation_common'
  end
end
