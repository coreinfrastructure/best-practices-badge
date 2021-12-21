# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class ProjectsControllerSpecialTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
  end

  test 'should fail to edit due to old session' do
    log_in_as(@project.user, make_old: true)
    get "/en/projects/#{@project.id}/edit"
    assert_response 302
    assert_redirected_to login_path
  end
end
