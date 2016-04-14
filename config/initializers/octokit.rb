Octokit.configure do |c|
  c.client_id = ENV['GITHUB_KEY']
  c.client_secret = ENV['GITHUB_SECRET']
  c.auto_paginate = true
end
