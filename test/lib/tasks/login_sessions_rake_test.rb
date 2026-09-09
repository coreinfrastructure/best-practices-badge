# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'rake'

# Coverage isn't required here (lib/tasks is excluded from the project's
# coverage requirement), but the task's two failure modes (missing
# argument, unknown user) matter enough to verify directly: this is an
# incident-response tool, and it should fail loudly, not silently no-op.
class LoginSessionsRakeTest < ActiveSupport::TestCase
  setup do
    # Load only this one task file, not Rails.application.load_tasks: that
    # loads every *.rake file in the project (including the 2700-line
    # default.rake, which runs top-level code such as
    # `task(:default).clear.enhance(...)` and `Rake::FileList.new(...)` the
    # moment it's loaded), which is unnecessary here and was observed to
    # have unrelated side effects when loaded mid-test-run.
    unless Rake::Task.task_defined?('environment')
      Rake.application.define_task(Rake::Task, :environment) {}
    end
    unless Rake::Task.task_defined?('login_sessions:revoke')
      load Rails.root.join('lib/tasks/login_sessions.rake').to_s
    end
    Rake::Task['login_sessions:revoke'].reenable
  end

  test 'revokes all login sessions for a valid user id' do
    user = users(:test_user)
    LoginSession.create_for(user, ip_address: '127.0.0.1', user_agent: 'a')
    LoginSession.create_for(user, ip_address: '127.0.0.1', user_agent: 'b')
    assert_equal 2, user.login_sessions.count

    out, =
      capture_io do
      Rake::Task['login_sessions:revoke'].invoke(user.id.to_s)
    end

    assert_equal 0, user.login_sessions.count
    assert_match(
      "Revoked 2 session(s) for user #{user.id} (#{user.name}).", out
    )
  end

  test 'raises on an unknown user id, rather than silently doing nothing' do
    assert_raises(ActiveRecord::RecordNotFound) do
      capture_io { Rake::Task['login_sessions:revoke'].invoke('999999999') }
    end
  end

  test 'exits nonzero when the user id argument is missing' do
    assert_raises(SystemExit) do
      capture_io { Rake::Task['login_sessions:revoke'].invoke }
    end
  end
end
