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

  test 'Criteria#keys' do
    assert_includes Criteria.keys, '0'
  end

  test 'Ensure that only allowed fields are in Criteria' do
    allowed_set = Set.new %i[
      category future na_allowed met_url_required met_justification_required
      na_justification_required met_suppress unmet_suppress autofill
      major minor rationale
    ]
    Criteria.to_h.each do |_level, criteria|
      criteria.each do |criterion, values|
        values.each do |key, value|
          puts "#{criterion}, #{values}" unless allowed_set.include?(key.to_sym)
          assert_includes allowed_set, key.to_sym
        end
      end
    end
  end

  test 'Ensure that only allowed fields are in Criteria translations' do
    # Make sure translations are initialized
    I18n.t('.')
    allowed_set = Set.new %i[
      description details met_placeholder unmet_placeholder na_placeholder
    ]
    translations = I18n.backend.send(:translations)
    translations.each do |_lang, locale|
      next unless locale.key?(:criteria)
      locale[:criteria].each do |_level, criteria|
        criteria.each do |_criterion, values|
          values.each do |key, _value|
            assert_includes allowed_set, key.to_sym
          end
        end
      end
    end
  end

  test 'Ensure that required fields are in Criteria and English translation' do
    required_set = Set.new %i[category major minor]
    Criteria.to_h.each do |level, criteria|
      criteria.each do |criterion, values|
        assert I18n.exists?(
          "criteria.#{level}.#{criterion}.description", :en
        )
        required_set.each do |required_field|
          assert_includes values.keys, required_field.to_s
        end
      end
    end
  end

  test 'Ensure only valid categories in Criteria' do
    Criteria.to_h.each do |_level, criteria|
      criteria.each do |_criterion, values|
        allowed_field_values = %w[MUST SHOULD SUGGESTED]
        assert_includes allowed_field_values, values['category']
      end
    end
  end

  test 'If URL required, do not suppress justification' do
    Criteria.to_h.each do |_level, criteria|
      criteria.each do |_criterion, values|
        assert_not values[:met_url_required] && values[:met_suppress]
      end
    end
  end

  test 'If Met justification required, do not suppress justification' do
    Criteria.to_h.each do |_level, criteria|
      criteria.each do |_criterion, values|
        assert_not values[:met_justification_required] && values[:met_suppress]
      end
    end
  end

  test 'If N/A justification required, do not suppress justification' do
    Criteria.to_h.each do |_level, criteria|
      criteria.each do |_criterion, values|
        assert_not values[:na_justification_required] && values[:met_suppress]
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
    Criteria.each do |_level, criteria|
      assert criteria.keys.length <= 100
    end
  end
end
