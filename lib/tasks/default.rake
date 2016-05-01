# Rake tasks for BadgeApp

# Run tests last. That way, runtime problems (e.g., undone migrations)
# do not interfere with the other checks.

task(:default).clear.enhance %w(
  rbenv_rvm_setup
  bundle
  bundle_audit
  rubocop
  markdownlint
  rails_best_practices
  brakeman
  license_okay
  license_finder_report.html
  whitespace_check
  yaml_syntax_check
  html_from_markdown
  fasterer
  eslint
  test
)

# Simple smoke test to avoid development environment misconfiguration
desc 'Ensure that rbenv or rvm are set up in PATH'
task :rbenv_rvm_setup do
  path = ENV['PATH']
  if !path.include?('.rbenv') && !path.include?('.rvm')
    raise 'Must have rbenv or rvm in PATH'
  end
end

desc 'Run Rubocop with options'
task :rubocop do
  sh 'bundle exec rubocop -D --format offenses --format progress || true'
end

desc 'Run rails_best_practices with options'
task :rails_best_practices do
  sh 'bundle exec rails_best_practices ' \
      '--features --spec --without-color || true'
end

desc 'Run brakeman'
task :brakeman do
  sh 'bundle exec brakeman --quiet'
end

desc 'Run bundle if needed'
task :bundle do
  sh 'bundle check || bundle install'
end

desc 'Run bundle-audit - check for known vulnerabilities in dependencies'
task :bundle_audit do
  verbose(false) do
    sh <<-END
      if ping -q -c 1 google.com > /dev/null 2> /dev/null ; then
        bundle exec bundle-audit update && bundle exec bundle-audit check
      else
        echo 'Cannot access rubygems.org, so skipping bundle_audit check'
        true # If we can't access google, don't bother.
      fi
    END
  end
end

desc 'Run markdownlint (mdl) - check for markdown problems'
task :markdownlint do
  style_file = 'config/markdown_style.rb'
  sh "bundle exec mdl -s #{style_file} *.md doc/*.md"
end

# Apply JSCS to look for issues in Javascript files.
# To use, must install jscs; the easy way is to use npm, and at
# the top directory of this project run "npm install jscs".
# This presumes that the jscs executable is installed in "node_modules/.bin/".
# See http://jscs.info/overview
#
# This not currently included in default "rake"; it *works* but is very
# noisy.  We need to determine which ruleset to apply,
# and we need to fix the Javascript to match that.
# We don't scan 'app/assets/javascripts/application.js';
# it is primarily auto-generated code + special directives.
desc 'Run jscs - Javascript style checker'
task :jscs do
  jscs_exe = 'node_modules/.bin/jscs'
  jscs_options = '--preset=node-style-guide -m 9999'
  jscs_files = 'app/assets/javascripts/project-form.js'
  sh "#{jscs_exe} #{jscs_options} #{jscs_files}"
end

desc 'Load current self.json'
task :load_self_json do
  require 'open-uri'
  require 'json'
  url = 'https://master.bestpractices.coreinfrastructure.org/projects/1.json'
  contents = open(url).read
  pretty_contents = JSON.pretty_generate(JSON.parse(contents))
  File.write('doc/self.json', pretty_contents)
end

# We use a file here because we do NOT want to run this check if there's
# no need.  We use the file 'license_okay' as a marker to record that we
# HAVE run this program locally.
desc 'Examine licenses of reused components; see license_finder docs.'
file 'license_okay' => ['Gemfile.lock', 'doc/dependency_decisions.yml'] do
  sh 'bundle exec license_finder && touch license_okay'
end

desc 'Create license report'
file 'license_finder_report.html' =>
     ['Gemfile.lock', 'doc/dependency_decisions.yml'] do
  sh 'bundle exec license_finder report --format html ' \
     '> license_finder_report.html'
end

desc 'Check for trailing whitespace in latest proposed (git) patch.'
task :whitespace_check do
  sh 'git diff --check'
end

desc 'Check YAML syntax (except project.yml, which is not straight YAML)'
task :yaml_syntax_check do
  # Don't check "project.yml" - it's not a straight YAML file, but instead
  # it's processed by ERB (even though the filename doesn't admit it).
  sh "find . -name '*.yml' ! -name 'projects.yml' -exec yaml-lint {} + | " \
     "grep -v '^Checking the content of' | grep -v 'Syntax OK'"
end

# The following are invoked as needed.

desc 'Create visualization of gem dependencies (requires graphviz)'
task :bundle_viz do
  sh 'bundle viz --version --requirements --format svg'
end

desc 'Deploy current origin/master to staging'
task :deploy_staging do
  sh 'git checkout staging && git pull && ' \
     'git merge --ff-only origin/master && git push && git checkout master'
end

desc 'Deploy current origin/staging to production'
task :deploy_production do
  sh 'git checkout production && git pull && ' \
     'git merge --ff-only origin/staging && git push && git checkout master'
end

rule '.html' => '.md' do |t|
  sh "script/my-markdown \"#{t.source}\" | script/my-patch-html > \"#{t.name}\""
end

markdown_files = Rake::FileList.new('*.md', 'doc/*.md')

# Use this task to locally generate HTML files from .md (markdown)
task 'html_from_markdown' => markdown_files.ext('.html')

desc 'Use fasterer to report Ruby constructs that perform poorly'
task :fasterer do
  sh 'fasterer'
end

# Implement full purge of Fastly CDN cache.  Invoke using:
#   heroku run --app HEROKU_APP_HERE rake fastly:purge
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

desc 'Copy database from production into development (requires access privs)'
task :pull_database do
  puts 'Getting database'
  # This fails, probably because we use Unix sockets with local db:
  # sh 'rake db:drop &&
  #     heroku pg:pull DATABASE_URL development --app production-bestpractices'
  sh 'heroku pg:backups capture --app production-bestpractices && \
      curl -o db/latest.dump `heroku pg:backups public-url \
        --app production-bestpractices` && \
      rake db:reset && \
      pg_restore --verbose --clean --no-acl --no-owner -U `whoami` \
        -d development db/latest.dump'
  puts 'You may need to run "rake db:migrate".'
end

Rails::TestTask.new('test:features' => 'test:prepare') do |t|
  t.pattern = 'test/features/**/*_test.rb'
end

# This gem isn't available in production
if Rails.env.production?
  task :eslint do
    puts 'Skipping eslint checking in production (libraries not available).'
  end
else
  require 'eslintrb/eslinttask'
  Eslintrb::EslintTask.new :eslint do |t|
    t.pattern = 'app/assets/javascripts/*.js'
    # If you modify the exclude_pattern, also modify file .eslintignore
    t.exclude_pattern = 'app/assets/javascripts/application.js'
    t.options = :eslintrc
  end
end

desc 'Stub do-nothing jobs:work task to eliminate Heroku log complaints'
task 'jobs:work' do
end

desc 'Run in fake_production mode'
# This tests the asset pipeline
task :fake_production do
  sh "RAILS_ENV=fake_production bundle exec rake assets:precompile"
  sh "RAILS_ENV=fake_production bundle check || bundle install"
  sh "RAILS_ENV=fake_production rails server -p 4000"
end

Rake::Task['test:run'].enhance ['test:features']
