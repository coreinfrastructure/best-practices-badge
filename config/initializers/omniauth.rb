# frozen_string_literal: true
Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.test?
    # Test app OAuth returns to a different port
    ENV['GITHUB_KEY'] = ENV['TEST_GITHUB_KEY']
    ENV['GITHUB_SECRET'] = ENV['TEST_GITHUB_SECRET']
  end
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'],
           scope: 'user:email, read:org'
end
