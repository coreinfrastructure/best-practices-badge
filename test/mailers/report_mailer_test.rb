# frozen_string_literal: true
require 'test_helper'
# See http://guides.rubyonrails.org/testing.html#testing-your-mailers

class ReportMailerTest < ActionMailer::TestCase
  setup do
    @perfect_project = projects(:perfect)
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
end
