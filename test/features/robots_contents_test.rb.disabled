# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Robots.txt is cached, since it usually is unchanged in execution.
# We must clear the cache so we can test under different circumstances.

require 'capybara_feature_test'

class RobotsProductionTest < CapybaraFeatureTest
  setup do
    Rails.cache.clear
    ENV['PUBLIC_HOSTNAME'] = 'bestpractices.coreinfrastructure.org'
  end

  teardown do
    ENV['PUBLIC_HOSTNAME'] = ''
  end

  scenario 'robots.txt on production site' do
    visit '/robots.txt'
    assert has_content? 'User-Agent: *'
    assert has_content? 'Allow: /'
    assert has_content? 'Disallow: /users'
    # Directly check for locales used by EU countries, ensure they're there
    assert has_content? 'Disallow: /en/users'
    assert has_content? 'Disallow: /fr/users'
    assert has_content? 'Disallow: /de/users'
    # Loop through all locales (make sure we didn't miss one)
    I18n.available_locales.each do |loc|
      assert has_content? "Disallow: /#{loc}/users"
    end
  end
end

class RobotsNonproductionTest < CapybaraFeatureTest
  setup do
    Rails.cache.clear
    ENV['PUBLIC_HOSTNAME'] = 'master.bestpractices.coreinfrastructure.org'
  end

  teardown do
    ENV['PUBLIC_HOSTNAME'] = ''
  end

  scenario 'robots.txt on nonproduction site' do
    visit '/robots.txt'
    assert has_content? 'User-Agent: *'
    assert_not has_content? 'Allow: /'
    assert has_content? 'Disallow: /'
  end
end
