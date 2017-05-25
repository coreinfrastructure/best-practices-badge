# frozen_string_literal: true

require 'test_helper'
require 'set'

# rubocop:disable Metrics/ClassLength
class CriteriaTest < ActiveSupport::TestCase
  test 'Criteria should have floss_license_osi' do
    assert Criteria['0'][:floss_license_osi]
  end

  test 'Criteria "contribution" is in the category MUST' do
    assert_equal 'MUST', Criteria['0'][:contribution].category
  end

  test 'Criteria "contribution_requirements" is in the category SHOULD' do
    assert_equal 'SHOULD', Criteria['0'][:contribution_requirements].category
  end

  test 'Criteria#all' do
    assert_includes Criteria.all, :contribution
  end

  test 'Criteria.active("0")' do
    active = Criteria.active('0').map(&:name)
    assert_includes active, :contribution
    refute_includes active, :hardening
  end

  test 'Criteria#keys' do
    assert_includes Criteria.keys, '0'
  end

  test '#details_present?' do
    assert Criteria['0'][:description_good].details_present?
    refute Criteria['0'][:version_tags].details_present?
  end

  test 'Ensure that only allowed fields are in Criteria' do
    allowed_set = Set.new %i[
      category future na_allowed met_url_required met_justification_required
      na_justification_required met_suppress unmet_suppress autofill
      major minor rationale
    ]
    Criteria.to_h.each do |_level, criteria_set|
      criteria_set.each do |_criterion, fields|
        fields.keys.each { |k| assert_includes allowed_set, k.to_sym }
      end
    end
  end

  test 'Ensure that only allowed fields are in Criteria translations' do
    allowed_set = Set.new %i[
      description details met_placeholder unmet_placeholder na_placeholder
    ]
    I18n.t('criteria').each do |_level, criteria_set|
      criteria_set.each do |_criterion, fields|
        fields.keys.each { |k| assert_includes allowed_set, k }
      end
    end
  end

  test 'Ensure that required fields are in Criteria and English translation' do
    required_set = Set.new %i[category major minor]
    Criteria.to_h.each do |level, criteria_set|
      criteria_set.each do |criterion, fields|
        assert I18n.exists?(
          "criteria.#{level}.#{criterion}.description", :en
        )
        required_set.each do |required_field|
          assert_includes fields.keys, required_field.to_s
        end
      end
    end
  end

  test 'All Criteria in each level have a description' do
    Criteria.each do |_level, criteria_set|
      criteria_set.values.each do |criterion|
        assert criterion.description.present?
      end
    end
  end

  test 'Ensure only valid categories in Criteria' do
    Criteria.to_h.each do |_level, criteria_set|
      criteria_set.each do |_criterion, fields|
        allowed_field_values = %w[MUST SHOULD SUGGESTED]
        assert_includes allowed_field_values, fields['category']
      end
    end
  end

  test 'If URL required, do not suppress justification' do
    Criteria.to_h.each do |_level, criteria_set|
      criteria_set.each do |_criterion, fields|
        assert_not fields[:met_url_required] && fields[:met_suppress]
      end
    end
  end

  test 'If Met justification required, do not suppress justification' do
    Criteria.to_h.each do |_level, criteria_set|
      criteria_set.each do |_criterion, fields|
        assert_not fields[:met_justification_required] && fields[:met_suppress]
      end
    end
  end

  test 'If N/A justification required, do not suppress justification' do
    Criteria.to_h.each do |_level, criteria_set|
      criteria_set.each do |_criterion, fields|
        assert_not fields[:na_justification_required] && fields[:met_suppress]
      end
    end
  end

  test 'Sample values correct for specific criteria' do
    assert Criteria['0'][:contribution].met_url_required?
    assert_not Criteria['0'][:floss_license_osi].met_url_required?

    assert Criteria['0'][:description_good].must?
    assert_not Criteria['0'][:contribution_requirements].must?

    assert Criteria['0'][:contribution_requirements].should?
    assert_not Criteria['0'][:description_good].should?

    assert Criteria['0'][:static_analysis].na_justification_required?
    assert_not Criteria['0'][:repo_distributed].na_justification_required?
  end

  # The "badge_percentage" and related values are currently integers 0..100;
  # that won't work well if we have > 100 criteria.
  # We can change the code later to address this; for now, let's make sure
  # the software stays within the limitation
  test 'No more than 100 criteria in each level' do
    Criteria.each do |_level, criteria_set|
      assert criteria_set.keys.length <= 100
    end
  end
end
