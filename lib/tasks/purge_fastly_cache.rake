# Implement full purge of Fastly CDN cache.  Invoke using:
#   heroku run rake fastly:purge --app NAME_OF_APPLICATION
# Run this if code changes will cause a change in badge level, since otherwise
# the old badge levels will keep being displayed until the cache times out.
# See: https://robots.thoughtbot.com/
# a-guide-to-caching-your-rails-application-with-fastly
namespace :fastly do
  desc 'Purge Fastly cache (takes about 5s)'
  task :purge do
    puts 'Starting full purge of Fastly cache (typically takes about 5s)'
    require Rails.root.join('config/initializers/fastly')
    FastlyRails.client.get_service(ENV.fetch('FASTLY_SERVICE_ID')).purge_all
    puts 'Cache purged'
  end
end
