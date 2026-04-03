# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
# See http://guides.rubyonrails.org/testing.html#testing-your-mailers

class ReportMailerTest < ActionMailer::TestCase
  setup do
    @perfect_project = projects(:perfect_passing)
    # @user = users(:test_user)
  end

  test 'Does ReportMailer project_status_change send anything?' do
    email = ReportMailer.project_status_change(
      @perfect_project, false, true
    ).deliver_now
    assert_not ActionMailer::Base.deliveries.empty?
    # We don't want to modify the test when we reconfigure things.
    # So instead of insisting on specific values, we'll just
    # do a 'smoke test' to quickly check that it's sane.
    assert_predicate email.from, :present?
    assert_predicate email.to, :present?
    assert_predicate email.subject, :present?
  end

  test 'email_owner gained metal badge uses /badge suffix' do
    email = ReportMailer.email_owner(
      @perfect_project, 'in_progress', 'passing', false, 'badge'
    ).deliver_now
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email.body.to_s, '/badge'
    assert_not_includes email.body.to_s, '/baseline'
  end

  test 'email_owner gained baseline badge uses /baseline suffix' do
    email = ReportMailer.email_owner(
      @perfect_project, 'in_progress', 'baseline-1', false, 'baseline'
    ).deliver_now
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email.body.to_s, '/baseline'
    assert_not_includes email.body.to_s, '/badge'
  end

  test 'Does the monthly announcement run?' do
    # This is a quick sanity test, not an in-depth test.
    # Use 'example.org' per RFC 2606
    ENV['REPORT_MONTHLY_EMAIL'] = 'mytest@example.org'
    awesome_projects = [
      [
        projects(:perfect_passing), projects(:perfect_silver),
        projects(:perfect)
      ], [projects(:perfect_silver), projects(:perfect)],
      [projects(:perfect)]
    ]
    email = ReportMailer
            .report_monthly_announcement(
              awesome_projects, '2015-02',
              project_stats(:one), project_stats(:two)
            )
            .deliver_now
    ENV['REPORT_MONTHLY_EMAIL'] = nil # Erase environment variable
    assert_not ActionMailer::Base.deliveries.empty?
    # We don't want to modify the test when we reconfigure things.
    # So instead of insisting on specific values, we'll just
    # do a 'smoke test' to quickly check that it's sane.
    assert_predicate email.from, :present?
    assert_predicate email.to, :present?
    assert_predicate email.subject, :present?
  end
end
