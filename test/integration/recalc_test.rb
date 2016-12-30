# frozen_string_literal: true
require 'test_helper'

class RecalcTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
  end

  test 'Recalc percentages' do
    # This is a lousy test that only checks if we can run
    # all_badge_percentages, not whether it produces correct results.
    # But it at least validates that it *runs*.
    Project.update_all_badge_percentages
    assert Project.find(projects(:one).id).badge_percentage.zero?
  end
end
