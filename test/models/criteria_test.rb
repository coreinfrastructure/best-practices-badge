# frozen_string_literal: true
require 'test_helper'
require 'set'

class CriteriaTest < ActiveSupport::TestCase
  test 'Criteria should have floss_license_osi' do
    assert Criteria[:floss_license_osi]
  end

  test 'Criteria "contribution" is in the category MUST' do
    assert_equal 'MUST', Criteria[:contribution].category
  end

  test 'Criteria "contribution_requirements" is in the category SHOULD' do
    assert_equal 'SHOULD', Criteria[:contribution_requirements].category
  end

  test 'Criteria#keys' do
    assert_includes Criteria.keys, :contribution
  end

  test 'Ensure that only allowed fields are in Criteria' do
    allowed_set = Set.new %i(
      category future na_allowed met_url_required description details
      met_placeholder unmet_placeholder na_placeholder met_suppress
      unmet_suppress autofill
    )
    Criteria.to_h.each do |_criterion, values|
      values.each do |key, _value|
        assert_includes allowed_set, key.to_sym
      end
    end
  end

  test 'Ensure that required fields are in Criteria' do
    required_set = Set.new %i(category description)
    Criteria.to_h.each do |_criterion, values|
      required_set.each do |required_field|
        assert_includes values.keys, required_field.to_s
      end
    end
  end

  test 'Ensure only valid categories in Criteria' do
    Criteria.to_h.each do |_criterion, values|
      allowed_field_values = %w(MUST SHOULD SUGGESTED)
      assert_includes allowed_field_values, values['category']
    end
  end

  test 'If URL required, do not suppress justification' do
    Criteria.to_h.each do |_criterion, values|
      assert_not values[:met_url_required] && values[:met_suppress]
    end
  end
end
