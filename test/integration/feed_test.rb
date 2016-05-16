# frozen_string_literal: true
require 'test_helper'
load 'Rakefile'

class FeedTest < ActionDispatch::IntegrationTest
  def setup
    # Normalize time in order to match fixture file
    travel_to Time.zone.parse('2015-03-01T12:00:00') do
      silence_stream(STDOUT) do
        # anything written to STDOUT here will be silenced
        Rake::Task['db:schema:load'].reenable
        Rake::Task['db:schema:load'].invoke
      end
      Rake::Task['db:fixtures:load'].reenable
      Rake::Task['db:fixtures:load'].invoke
    end
  end

  test 'feed matches fixture file' do
    get feed_path
    assert_equal contents('feed.atom'), response.body
  end
end
