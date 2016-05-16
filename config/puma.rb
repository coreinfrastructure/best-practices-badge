# frozen_string_literal: true
# Setup puma web server. See:
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
# threads_count = Integer(ENV['MAX_THREADS'] || 5)
# For now, *force* thread count to 1, to avoid threading problems.
threads_count = 1
threads threads_count, threads_count

preload_app!

rackup DefaultRackup
port ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+.  See:
  # https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
  if defined?(Resque)
    Resque.redis = ENV['<redis-uri>'] || 'redis://127.0.0.1:6379'
  end
end
