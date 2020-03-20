# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# TODO: ActionController::TestCase is obsolete. This should switch to using
# ActionDispatch::IntegrationTest and then remove rails-controller-testing.
# See: https://github.com/rails/rails/issues/22496
# However, these tests are hard to transition, so these remain.
class ProjectsControllerSpecialTest < ActionController::TestCase
  tests ProjectsController

  setup do
    @project = projects(:one)
  end

  test 'should fail to edit due to old session' do
    log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
    get :edit, params: { id: @project, locale: :en }
    assert_response 302
    assert_redirected_to login_path
  end

  test 'should fail to edit due to session time missing' do
    log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
    session.delete(:time_last_used)
    get :edit, params: { id: @project, locale: :en }
    assert_response 302
    assert_redirected_to login_path
  end
end
