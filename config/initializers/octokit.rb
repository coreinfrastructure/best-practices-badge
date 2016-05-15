# frozen_string_literal: true
Octokit.configure do |c|
  if Rails.env.test?
    # Test app OAuth returns to a different port
    ENV['GITHUB_KEY'] = ENV['TEST_GITHUB_KEY']
    ENV['GITHUB_SECRET'] = ENV['TEST_GITHUB_SECRET']
  end
  c.client_id = ENV['GITHUB_KEY']
  c.client_secret = ENV['GITHUB_SECRET']
  c.auto_paginate = true
end
