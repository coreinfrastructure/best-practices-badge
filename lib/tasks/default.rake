# frozen_string_literal: true
# Rake tasks for BadgeApp

task(:default).clear.enhance %w(
  rbenv_rvm_setup
  bundle
  bundle_doctor
  bundle_audit
  generate_criteria_doc
  rubocop
  markdownlint
  rails_best_practices
  brakeman
  license_okay
  license_finder_report.html
  whitespace_check
  yaml_syntax_check
  html_from_markdown
  eslint
  test
)
# Temporarily removed fasterer
# Waiting for Ruby 2.4 support: https://github.com/seattlerb/ruby_parser/issues/239

task(:ci).clear.enhance %w(
  rbenv_rvm_setup
  bundle_doctor
  bundle_audit
  markdownlint
  license_okay
  license_finder_report.html
  whitespace_check
  yaml_syntax_check
)
# Temporarily removed fasterer

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
  sh 'bundle exec rubocop -D --format offenses --format progress'
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

desc 'Run bundle doctor - check for some Ruby gem configuration problems'
task :bundle_doctor do
  sh 'bundle doctor'
end

# rubocop: disable Metrics/BlockLength
desc 'Run bundle-audit - check for known vulnerabilities in dependencies'
task :bundle_audit do
  verbose(true) do
    sh <<-END
      apply_bundle_audit=t
      if ping -q -c 1 github.com > /dev/null 2> /dev/null ; then
        echo "Have network access, trying to update bundle-audit database."
        tries_left=10
        while [ "$tries_left" -gt 0 ] ; do
          if bundle exec bundle-audit update ; then
            echo 'Successful bundle-audit update.'
            break
          fi
          sleep 2
          tries_left=$((tries_left - 1))
          echo "Bundle-audit update failed. Number of tries left=$tries_left"
        done
        if [ "$tries_left" -eq 0 ] ; then
          echo "Bundle-audit update failed after multiple attempts. Skipping."
          apply_bundle_audit=f
        fi
      else
        echo "Cannot update bundle-audit database; using current data."
      fi
      if [ "$apply_bundle_audit" = 't' ] ; then
        bundle exec bundle-audit check
      else
        true
      fi
    END
  end
end
# rubocop: enable Metrics/BlockLength

# Note: If you don't want mdl to be run on a markdown file, rename it to
# end in ".markdown" instead.  (E.g., for markdown fragments.)
desc 'Run markdownlint (mdl) - check for markdown problems on **.md files'
task :markdownlint do
  style_file = 'config/markdown_style.rb'
  sh "bundle exec mdl -s #{style_file} *.md doc/*.md"
end

# Apply JSCS to look for issues in JavaScript files.
# To use, must install jscs; the easy way is to use npm, and at
# the top directory of this project run "npm install jscs".
# This presumes that the jscs executable is installed in "node_modules/.bin/".
# See http://jscs.info/overview
#
# This not currently included in default "rake"; it *works* but is very
# noisy.  We need to determine which ruleset to apply,
# and we need to fix the JavaScript to match that.
# We don't scan 'app/assets/javascripts/application.js';
# it is primarily auto-generated code + special directives.
desc 'Run jscs - JavaScript style checker'
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
  if ENV['CI'] # CircleCI modifies database.yml
    sh "git diff --check -- . ':!config/database.yml'"
  else
    sh 'git diff --check'
  end
end

desc 'Check YAML syntax (except project.yml, which is not straight YAML)'
task :yaml_syntax_check do
  # Don't check "project.yml" - it's not a straight YAML file, but instead
  # it's processed by ERB (even though the filename doesn't admit it).
  sh "find . -name '*.yml' ! -name 'projects.yml' " \
     "! -path './vendor/*' -exec bundle exec yaml-lint {} + | " \
     "grep -v '^Checking the content of' | grep -v 'Syntax OK'"
end

# The following are invoked as needed.

desc 'Create visualization of gem dependencies (requires graphviz)'
task :bundle_viz do
  sh 'bundle viz --version --requirements --format svg'
end

desc 'Deploy current origin/master to staging'
task deploy_staging: :production_to_staging do
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

file 'doc/criteria.md' =>
     [
       'criteria.yml',
       'doc/criteria-header.markdown', 'doc/criteria-footer.markdown',
       './gen_markdown.rb'
     ] do
  sh './gen_markdown.rb'
end

# Name task so we don't have to use the filename
task generate_criteria_doc: 'doc/criteria.md' do
end

desc 'Use fasterer to report Ruby constructs that perform poorly'
task :fasterer do
  sh 'fasterer'
end

# rubocop: disable Metrics/BlockLength
# Tasks for Fastly including purging and testing the cache.
namespace :fastly do
  # Implement full purge of Fastly CDN cache.  Invoke using:
  #   heroku run --app HEROKU_APP_HERE rake fastly:purge
  # Run this if code changes will cause a change in badge level, since otherwise
  # the old badge levels will keep being displayed until the cache times out.
  # See: https://robots.thoughtbot.com/
  # a-guide-to-caching-your-rails-application-with-fastly
  desc 'Purge Fastly cache (takes about 5s)'
  task :purge do
    puts 'Starting full purge of Fastly cache (typically takes about 5s)'
    require Rails.root.join('config', 'initializers', 'fastly')
    FastlyRails.client.get_service(ENV.fetch('FASTLY_SERVICE_ID')).purge_all
    puts 'Cache purged'
  end

  desc 'Test Fastly Caching'
  task :test, [:site_name] do |_t, args|
    args.with_defaults site_name:
      'https://master.bestpractices.coreinfrastructure.org/projects/1/badge'
    puts 'Starting test of Fastly caching'
    verbose(false) do
      sh <<-END
        site_name="#{args.site_name}"
        echo "Purging Fastly cache of badge for ${site_name}"
        curl -X PURGE "$site_name" || exit 1
        if curl -svo /dev/null "$site_name" 2>&1 | grep 'X-Cache: MISS' ; then
          echo "Fastly cache of badge for project 1 successfully purged."
        else
          echo "Failed to purge badge for project 1 from Fastly cache."
          exit 1
        fi
        if curl -svo /dev/null "$site_name" 2>&1 | grep 'X-Cache: HIT' ; then
          echo "Fastly cache successfully restored."
        else
          echo "Fastly failed to restore cache."
          exit 1
        fi
      END
    end
  end
end
# rubocop: enable Metrics/BlockLength

desc 'Drop development database'
task :drop_database do
  puts 'Dropping database development'
  # Command from http://stackoverflow.com/a/13245265/1935918
  sh "echo 'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM " \
     'pg_stat_activity WHERE datname = current_database() AND ' \
     "pg_stat_activity.pid <> pg_backend_pid();' | psql development; " \
     'dropdb -e development'
end

desc 'Copy database from production into development (requires access privs)'
task :pull_production do
  puts 'Getting production database'
  Rake::Task['drop_database'].reenable
  Rake::Task['drop_database'].invoke
  sh 'heroku pg:pull DATABASE_URL development --app production-bestpractices'
  Rake::Task['db:migrate'].reenable
  Rake::Task['db:migrate'].invoke
end

# Don't use this one unless you need to
desc 'Copy database from production into development (if normal one fails)'
task :pull_production_alternative do
  puts 'Getting production database (alternative)'
  sh 'heroku pg:backups:capture --app production-bestpractices && ' \
     'curl -o db/latest.dump `heroku pg:backups:public-url ' \
     '     --app production-bestpractices` && ' \
     'rake db:reset && ' \
     'pg_restore --verbose --clean --no-acl --no-owner -U `whoami` ' \
     '           -d development db/latest.dump'
end

desc 'Copy database from master into development (requires access privs)'
task :pull_master do
  puts 'Getting master database'
  Rake::Task['drop_database'].reenable
  Rake::Task['drop_database'].invoke
  sh 'heroku pg:pull DATABASE_URL development --app master-bestpractices'
  Rake::Task['db:migrate'].reenable
  Rake::Task['db:migrate'].invoke
end

desc 'Copy production database to master, overwriting master database'
task :production_to_master do
  sh 'heroku pg:backups:restore $(heroku pg:backups:public-url ' \
     '--app production-bestpractices) DATABASE_URL --app master-bestpractices'
  sh 'heroku run:detached bundle exec rake db:migrate ' \
     '--app master-bestpractices'
end

desc 'Copy production database to staging, overwriting staging database'
task :production_to_staging do
  sh 'heroku pg:backups:restore $(heroku pg:backups:public-url ' \
     '--app production-bestpractices) DATABASE_URL ' \
     '--app staging-bestpractices --confirm staging-bestpractices'
  sh 'heroku run:detached bundle exec rake db:migrate ' \
     '--app staging-bestpractices'
end

# require 'rails/testtask.rb'
# Rails::TestTask.new('test:features' => 'test:prepare') do |t|
#   t.pattern = 'test/features/**/*_test.rb'
# end

task 'test:features' => 'test:prepare' do
  $LOAD_PATH << 'test'
  Minitest.rake_run(['test/features'])
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
  sh 'RAILS_ENV=fake_production bundle exec rake assets:precompile'
  sh 'RAILS_ENV=fake_production bundle check || bundle install'
  sh 'RAILS_ENV=fake_production rails server -p 4000'
end

# Use this if the badge rules change.  This will email those who
# gain/lose a badge because of the changes.
desc 'Run to recalculate all badge percentages for all projects'
task :update_all_badge_percentages do
  Project.update_all_badge_percentages
end

Rake::Task['test:run'].enhance ['test:features']

# This is the task to run every day, e.g., to record statistics
# Configure your system (e.g., Heroku) to run this daily.  If you're using
# Heroku, see: https://devcenter.heroku.com/articles/scheduler
desc 'Run daily tasks used in any tier, e.g., record daily statistics'
task daily: :environment do
  ProjectStat.create!
end

# Run this task to email a limited set of reminders to inactive projects
# that do not have a badge.
# Configure your system (e.g., Heroku) to run this daily.  If you're using
# Heroku, see: https://devcenter.heroku.com/articles/scheduler
desc 'Send reminders to the oldest inactive project badge entries.'
task reminders: :environment do
  puts 'Sending inactive project reminders. List of reminded project ids:'
  p ProjectsController.send :send_reminders
  true
end

# Run this task periodically if we want to test the
# install-badge-dev-environment script
desc 'check that install-badge-dev-environment works'
task :test_dev_install do
  puts 'Updating test-dev-install branch'
  sh <<-END
    git checkout test-dev-install
    git merge --no-commit master
    git checkout HEAD circle.yml
    git commit -a -s -m "Merge master into test-dev-install"
    git push origin test-dev-install
    git checkout master
  END
end
