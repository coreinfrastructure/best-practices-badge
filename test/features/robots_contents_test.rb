# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'capybara_feature_test'

class RobotsProductionTest < CapybaraFeatureTest
  setup do
    ENV['PUBLIC_HOSTNAME'] = 'bestpractices.coreinfrastructure.org'
  end

  teardown do
    ENV['PUBLIC_HOSTNAME'] = ''
  end

  scenario 'robots.txt on production site' do
    visit '/robots.txt'
    assert has_content? 'User-Agent: *'
    assert has_content? 'Allow: /'
    refute has_content? 'Disallow: /'
  end
end

class RobotsNonproductionTest < CapybaraFeatureTest
  setup do
    ENV['PUBLIC_HOSTNAME'] = 'master.bestpractices.coreinfrastructure.org'
  end

  teardown do
    ENV['PUBLIC_HOSTNAME'] = ''
  end

  scenario 'robots.txt on nonproduction site' do
    visit '/robots.txt'
    assert has_content? 'User-Agent: *'
    refute has_content? 'Allow: /'
    assert has_content? 'Disallow: /'
  end
end
