require 'test_helper'
require 'set'

class CriteriaTest < ActiveSupport::TestCase
  def setup
  end

  test 'Criteria should have contribution_criteria' do
    assert Criteria[:contribution_criteria]
  end

  test 'Criteria "contribution" is in the category MUST' do
    assert_equal 'MUST', Criteria[:contribution][:category]
  end

  test 'Criteria "contribution_criteria" is in the category SHOULD' do
    assert_equal 'SHOULD', Criteria[:contribution_criteria][:category]
  end

  test 'Ensure that only allowed fields are in Criteria' do
    allowed_set = Set.new [:category, :na_allowed, :met_url_required,
                           :description, :details,
                           :met_placeholder, :unmet_placeholder,
                           :na_placeholder,
                           :met_suppress, :unmet_suppress]
    Criteria.each do |_criterion, values|
      values.each do |key, _value|
        assert_includes allowed_set, key.to_sym
      end
    end
  end

  test 'If URL required, do not suppress justification' do
    Criteria.each do |_criterion, values|
      assert_not values[:met_url_required] && values[:met_suppress]
    end
  end
end
