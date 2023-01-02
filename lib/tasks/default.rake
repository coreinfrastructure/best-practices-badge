# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Rake tasks for BadgeApp

require 'json'

task(:default).clear.enhance %w[
  rbenv_rvm_setup
  bundle
  bundle_audit
  generate_criteria_doc
  rubocop
  markdownlint
  rails_best_practices
  license_okay
  license_finder_report.html
  whitespace_check
  yaml_syntax_check
  html_from_markdown
  eslint
  report_code_statistics
  update_chromedriver
  test
]
# Temporarily removed fasterer
# Waiting for Ruby 2.4 support: https://github.com/seattlerb/ruby_parser/issues/239
# Temporarily removed railroader because of local install problems;
# it's still run by the CI for every pull request

# Run Continuous Integration (CI) check processes.
# This is a shorter list; many checks are run by a separate "pronto" task.
# Temporarily includes "railroader", we hope to move that to pronto.
# Removed bundle_doctor due to CircleCI failures
# Temporarily removed fasterer
task(:ci).clear.enhance %w[
  rbenv_rvm_setup
  bundle_audit
  markdownlint
  license_okay
  license_finder_report.html
  whitespace_check
  yaml_syntax_check
  report_code_statistics
  railroader
]

# Simple smoke test to avoid development environment misconfiguration
desc 'Ensure that rbenv or rvm are set up in PATH'
task :rbenv_rvm_setup do
  path = ENV.fetch('PATH', nil)
  if !path.include?('.rbenv') && !path.include?('.rvm')
    raise RuntimeError 'Must have rbenv or rvm in PATH'
  end
end

desc 'Run Rubocop with options'
task :rubocop do
  sh 'bundle exec rubocop -D --format progress'
end

desc 'Run rails_best_practices with options'
task :rails_best_practices do
  sh 'bundle exec rails_best_practices --features --spec --without-color --exclude railroader/'
end

desc 'Setup railroader if needed'
task 'railroader/bin/railroader' do
  # "gem install" doesn't honor Gemfile.lock, so use git clone + bundle install
  sh 'mkdir -p railroader'
  sh 'cd railroader; ' \
     'git clone --depth 1 ' \
     'https://github.com/david-a-wheeler/railroader.git ./ ; ' \
     'cp ../.ruby-version .; bundle install'
end

desc 'Run railroader'
task railroader: %w[railroader/bin/railroader] do
  # TEMPORARY: DISABLE
  # Disable pager, so that "rake" can keep running without halting.
  # sh 'bundle exec railroader --quiet --no-pager'
  # Workaround to run correct version of railroader & its dependencies.
  # We have to set BUNDLE_GEMFILE so bundle works inside the rake task
  sh 'cd railroader; BUNDLE_GEMFILE=$(pwd)/Gemfile bundle exec bin/railroader --quiet --no-pager $(dirname $(pwd))'
end

desc 'Run bundle if needed'
task :bundle do
  sh 'bundle check || bundle install'
end

# NOTE: We've had some trouble with bundle doctor, so it might
# not be run by default.
desc 'Run bundle doctor - check for some Ruby gem configuration problems'
task :bundle_doctor do
  sh 'bundle doctor'
end

desc 'Report code statistics'
task :report_code_statistics do
  verbose(false) do
    sh 'script/report_code_statistics'
  end
end

# rubocop: disable Metrics/BlockLength
desc 'Run bundle-audit - check for known vulnerabilities in dependencies'
task :bundle_audit do
  verbose(true) do
    sh <<-RETRY_BUNDLE_AUDIT_SHELL
      apply_bundle_audit=t
      if ping -q -c 1 github.com > /dev/null 2> /dev/null; then
        echo "Have network access, trying to update bundle-audit database."
        tries_left=10
        while [ "$tries_left" -gt 0 ] ; do
          if bundle exec bundle audit update ; then
            echo 'Successful bundle audit update.'
            break
          fi
          sleep 2
          tries_left=$((tries_left - 1))
          echo "Bundle audit update failed. Number of tries left=$tries_left"
        done
        if [ "$tries_left" -eq 0 ] ; then
          echo "Bundle audit update failed after multiple attempts. Skipping."
          apply_bundle_audit=f
        fi
      else
        echo "Cannot update bundle-audit database; using current data."
      fi
      if [ "$apply_bundle_audit" = 't' ] ; then
        # Ignore CVE-2015-9284 (omniauth); We have mitigated this with a
        # third-party countermeasure (omniauth-rails_csrf_protection) in:
        # https://github.com/coreinfrastructure/best-practices-badge/pull/1298
        bundle exec bundle audit check --ignore CVE-2015-9284
      else
        true
      fi
    RETRY_BUNDLE_AUDIT_SHELL
  end
end
# rubocop: enable Metrics/BlockLength

# NOTE: If you don't want mdl to be run on a markdown file, rename it to
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
  require 'json'
  require 'open-uri'
  url = 'https://master.bestpractices.coreinfrastructure.org/projects/1.json'
  contents = URI.parse(url).open.read
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
file 'license_finder_report.html' => [
  'Gemfile.lock',
  'doc/dependency_decisions.yml'
] do
  sh 'bundle exec license_finder report --format html > license_finder_report.html'
end

# Don't do whitespace checks on these YAML files:
YAML_WS_EXCEPTIONS = ':!test/vcr_cassettes/*.yml'

desc 'Check for trailing whitespace in latest proposed (git) patch.'
task :whitespace_check do
  if ENV['CI'] # CircleCI modifies database.yml
    sh "git diff --check -- . ':!config/database.yml' #{YAML_WS_EXCEPTIONS}"
  else
    sh "git diff --check -- . #{YAML_WS_EXCEPTIONS}"
  end
end

desc 'Check YAML syntax (except project.yml, which is not straight YAML)'
task :yaml_syntax_check do
  # Don't check "project.yml" - it's not a straight YAML file, but instead
  # it's processed by ERB (even though the filename doesn't admit it).
  sh "find . -name '*.yml' ! -name 'projects.yml' ! -path './railroader/*' " \
     "! -path './vendor/*' -exec bundle exec yaml-lint {} + ;"
end

# The following are invoked as needed.

desc 'Create visualization of gem dependencies (requires graphviz)'
task :bundle_viz do
  sh 'bundle viz --version --requirements --format svg'
end

desc 'Deploy current origin/main to staging'
task deploy_staging: :production_to_staging do
  sh 'git checkout staging && git pull && git merge --ff-only origin/main && git push && git checkout main'
end

desc 'Deploy current origin/staging to production'
task :deploy_production do
  sh 'git checkout production && git pull && git merge --ff-only origin/staging && git push && git checkout main'
end

rule '.html' => '.md' do |t|
  sh "script/my-markdown \"#{t.source}\" | script/my-patch-html > \"#{t.name}\""
end

markdown_files = Rake::FileList.new('*.md', 'doc/*.md')

# Use this task to locally generate HTML files from .md (markdown)
task 'html_from_markdown' => markdown_files.ext('.html')

file 'doc/criteria.md' =>
     [
       'criteria/criteria.yml', 'config/locales/en.yml',
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

# Tasks for Fastly including purging and testing the cache.
namespace :fastly do
  # Implement purge_all (full purge) of Fastly CDN cache.  Invoke using:
  #   heroku run --app HEROKU_APP_HERE -- rake fastly:purge
  # Run this if code changes will cause a change in badge level, since otherwise
  # the old badge levels will keep being displayed until the cache times out.
  # See: https://robots.thoughtbot.com/
  # a-guide-to-caching-your-rails-application-with-fastly
  # This will cause a SIGNIFICANT temporary increase in activity, since
  # it will completely empty the CDN cache.
  # This requires environment variables to be set, specifically
  # 'FASTLY_API_KEY' and 'FASTLY_SERVICE_ID'. See:
  # https://developer.fastly.com/reference/api/purging/
  # Basically, we'll do POST /service/service_id/purge_all
  # Unfortunately we *cannot* do a soft purge, "Fastly-Soft-Purge: 1"
  # on a purge-all, per the Fastly documentation.
  desc 'Purge ALL of Fastly cache (takes about 5s)'
  task :purge_all do
    puts 'Starting purge ALL of Fastly cache (typically takes about 5s)'
    # The following is needed to load fastly_rails without bringing in the
    # entire Rails environment (which we don't need).
    $LOAD_PATH.append("#{Dir.getwd}/app/lib")
    require 'fastly_rails'
    FastlyRails.purge_all
    puts 'Cache purged'
  end

  desc 'Test Fastly Caching'
  task :test, [:site_name] do |_t, args|
    args.with_defaults site_name: 'https://master.bestpractices.coreinfrastructure.org/projects/1/badge'
    puts 'Starting test of Fastly caching'
    verbose(false) do
      sh "script/fastly_test #{args.site_name}"
    end
  end
end

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
desc 'Copy active production database into development (if normal one fails)'
task :pull_production_alternative do
  puts 'Getting production database (alternative)'
  sh 'heroku pg:backups:capture --app production-bestpractices && ' \
     'curl -o db/latest.dump `heroku pg:backups:public-url ' \
     '     --app production-bestpractices` && ' \
     'rake db:reset && ' \
     'pg_restore --verbose --clean --no-acl --no-owner -U `whoami` ' \
     '           -d development db/latest.dump'
end

desc 'Copy active main database into development (requires access privs)'
task :pull_main do
  puts 'Getting main database'
  Rake::Task['drop_database'].reenable
  Rake::Task['drop_database'].invoke
  sh 'heroku pg:pull DATABASE_URL development --app master-bestpractices'
  Rake::Task['db:migrate'].reenable
  Rake::Task['db:migrate'].invoke
end

# This just copies the most recent backup of production; in almost
# all cases this is adequate, and this way we don't disturb production
# unnecessarily.  If you want the current active database, you can
# force a backup with:
# heroku pg:backups:capture --app production-bestpractices
desc 'Copy production database backup to main stage, overwriting main database'
task :production_to_main do
  sh 'heroku pg:backups:restore $(heroku pg:backups:public-url ' \
     '--app production-bestpractices) DATABASE_URL --app master-bestpractices'
  sh 'heroku run:detached bundle exec rake db:migrate --app master-bestpractices'
end

desc 'Copy production database backup to staging, overwriting staging database'
task :production_to_staging do
  sh 'heroku pg:backups:restore $(heroku pg:backups:public-url ' \
     '--app production-bestpractices) DATABASE_URL ' \
     '--app staging-bestpractices --confirm staging-bestpractices'
  sh 'heroku run:detached bundle exec rake db:migrate --app staging-bestpractices'
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
# Use string comparison, because Rubocop doesn't know about fake_production
if Rails.env.production? || Rails.env == 'fake_production'
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

# rubocop:disable Metrics/MethodLength
def normalize_values(input, locale)
  # The destination locale is "locale".
  input.transform_values! do |value|
    if value.is_a?(Hash)
      normalize_values value, locale
    elsif value.is_a?(String)
      normalize_string value, locale
    elsif value.is_a?(NilClass)
      value
    else
      raise TypeError 'Not Hash, String or NilClass'
    end
  end
end
# rubocop:enable Metrics/MethodLength

# rubocop:disable Metrics/MethodLength
def normalize_string(value, locale)
  # Remove trailing whitespace
  value.sub!(/\s+$/, '')
  return value unless value.include?('<')

  # Google Translate generates html text that has predictable errors.
  # The last entry mitigates the target=... vulnerability.  We don't need
  # to "counter" attacks from ourselves, but it does no harm and it's
  # easier to protect against everything.
  value.gsub(/< a /, '<a ')
       .gsub(/< \057/, '</')
       .gsub(/<\057 /, '</')
       .gsub(/<Strong>/, '<strong>')
       .gsub(/<Em>/, '<em>')
       .gsub(/ Href *=/, 'href=')
       .gsub(/href = /, 'href=')
       .gsub(/class = /, 'class=')
       .gsub(/target = /, 'target=')
       .gsub(/target="_ blank">/, 'target="_blank">')
       .gsub(/target="_blank" *>/, 'target="_blank" rel="noopener">')
       .gsub(%r{https: // }, 'https://')
       .gsub(%r{href="/en/}, "href=\"/#{locale}/")
       .gsub(%r{href='/en/}, "href='/#{locale}/")
end
# rubocop:enable Metrics/MethodLength

def normalize_yaml(path)
  # Reformats with a line-width of 80, removes trailing whitespace from all
  # values and fixes some predictable errors automatically.
  require 'yaml'
  Dir[path].each do |filename|
    # Compute locale from filename (it must be before the last period)
    locale = filename.split('.')[-2]
    normalized = normalize_values(YAML.load_file(filename), locale)
    File.write(filename, normalized.to_yaml(line_width: 60).gsub(/\s+$/, ''))
  end
end

desc "Ensure you're on the main branch"
task :ensure_main do
  raise StandardError, 'Must be on main branch to proceed' unless
    `git rev-parse --abbrev-ref HEAD` == "main\n"

  puts 'On main branch, proceeding...'
end

desc 'Reformat en.yml'
task :reformat_en do
  normalize_yaml Rails.root.join('config', 'locales', 'en.yml')
end

desc 'Fix locale text'
task :fix_localizations do
  normalize_yaml Rails.root.join('config', 'locales', 'translation.*.yml')
end

desc 'Save English translation file as .ORIG file'
task :backup_en do
  FileUtils.cp Rails.root.join('config', 'locales', 'en.yml'),
               Rails.root.join('config', 'locales', 'en.yml.ORIG'),
               preserve: true # this is the equivalent of cp -p
end

desc 'Restore English translation file from .ORIG file'
task :restore_en do
  FileUtils.mv Rails.root.join('config', 'locales', 'en.yml.ORIG'),
               Rails.root.join('config', 'locales', 'en.yml')
end

# The "translation:sync" task syncs up the translations, but uses the usual
# YAML writer, which writes out trailing whitespace.  It should not do that,
# and the trailing whitespace causes later failures in testing, so we fix.
# Problem already reported:
# - https://github.com/aurels/translation-gem/issues/13
# - https://github.com/yaml/libyaml/issues/46
# We save and restore the en version around the sync to resolve.
# Ths task only runs in development, since the gem is only loaded then.
if Rails.env.development?
  Rake::Task['translation:sync'].enhance %w[ensure_main backup_en] do
    at_exit do
      Rake::Task['restore_en'].invoke
      Rake::Task['fix_localizations'].invoke
      puts "Now run: git commit -sam 'rake translation:sync'"
    end
  end
end

desc 'Fix Gravatar use_gravatar fields for local users'
task fix_use_gravatar: :environment do
  User.where(provider: 'local').find_each do |u|
    actually_exists = u.gravatar_exists
    if u.use_gravatar != actually_exists # Changed result - set and store
      # Use "update_column" so that updated_at isn't changed, and also
      # to do things more quickly.  There are no model validations that
      # can be affected setting this boolean value, so let's skip them.
      # rubocop: disable Rails/SkipsModelValidations
      u.update_column(:use_gravatar, actually_exists)
      # rubocop: enable Rails/SkipsModelValidations
    end
  end
end

require 'net/http'
# Request uri, reply true if fetchable. Follow redirects 'limit' times.
# See: https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html
# rubocop:disable Metrics/MethodLength
def fetchable?(uri_str, limit = 10)
  return false if limit <= 0

  # Use GET, not HEAD. Some websites will say a page doesn't exist when given
  # a HEAD request, yet will redirect correctly on a GET request. Ugh.
  response = Net::HTTP.get_response(URI.parse(uri_str))
  case response
  when Net::HTTPSuccess then
    return true
  when Net::HTTPRedirection then
    # Recurse, because redirection might be to a different site
    location = response['location']
    warn "    redirected to <#{location}>"
    return fetchable?(location, limit - 1)
  else
    return false
  end
end
# rubocop:enable Metrics/MethodLength

def link_okay?(link)
  return false if link.blank?
  # '%{..}' is used when we generate URLs, presume they're okay.
  return true if link.start_with?('mailto:', '/', '#', '%{')
  # Shortcut: If we have anything other than http/https, it's wrong.
  return false unless link.start_with?('https://', 'http://')
  # Quick check - if there's a character other than URI-permitted, fail.
  # Note that space isn't included (including space is a common error).
  return false if %r{[^-A-Za-z0-9_\.~!*'\(\);:@\&=+\$,\/\?#\[\]%]}.match?(link)

  warn "  <#{link}>"
  fetchable?(link)
end

require 'set'
def validate_links_in_string(translation, from, seen)
  translation.scan(/href=["'][^"']+["']/).each do |snippet|
    link = snippet[6..-2]
    next if seen.include?(link) # Already seen it, don't complain again.

    if link_okay?(link)
      seen.add(link)
    else
      # Don't add failures to what we've seen, so that we report all failures
      puts "\nFAILED LINK IN #{from.join('.')} : <#{link}>"
    end
  end
end

# Recursive validate links.  "seen" refers to a set of links already seen.
# To recurse we really want kind_of?, not is_a?, so disable rubocop rule
# rubocop:disable Style/ClassCheck
def validate_links(translation, from, seen)
  if translation.kind_of?(Array)
    translation.each_with_index do |i, part|
      validate_links(part, from + [i], seen)
    end
  elsif translation.kind_of?(Hash)
    translation.each { |key, part| validate_links(part, from + [key], seen) }
  elsif translation.kind_of?(String) # includes safe_html
    validate_links_in_string(translation.to_s, from, seen)
  end
end
# rubocop:enable Style/ClassCheck

desc 'Validate hypertext links'
task validate_hypertext_links: :environment do
  seen = Set.new # Track what we've already seen (we'll skip them)
  I18n.available_locales.each do |loc|
    validate_links I18n.t('.', locale: loc), [loc], seen
  end
end

# Convert project.json -> project.sql (a command to re-insert data).
# This only *generates* a SQL command; I did it this way so that it's easy
# to check the command to be run *before* executing it, and this also makes
# it easy to separately determine the database to apply the command to.
# Note that this depends on non-standard PostgreSQL extensions.
desc 'Convert file "project.json" into SQL insertion command in "project.sql".'
task :create_project_insertion_command do
  puts 'Reading file project.json (this uses PostgreSQL extensions)'
  file_contents = File.read('project.json')
  data_hash = JSON.parse(file_contents)
  project_id = data_hash['id']
  puts "Inserting project id #{project_id}"
  # Escape JSON using SQL escape ' -> '', so we can use it in a SQL command
  escaped_json = "'" + file_contents.gsub(/'/, "''") + "'"
  sql_command = 'insert into projects select * from ' + "json_populate_record(NULL::projects, #{escaped_json});"
  File.write('project.sql', sql_command)
  puts 'File project.sql created. To use this, do the following (examples):'
  puts 'Local:  rails db < project.sql'
  puts 'Remote: heroku pg:psql --app production-bestpractices < project.sql'
end

# Change owner of PROJECT to USER. Both must be numbers. To use:
# heroku run --app production-bestpractices rake change_owner -- PROJECT OWNER
# You can run a SQL command to do this instead, but an error such as
# forgetting the WHERE clause can cause a big mistake. The statement would be:
# echo "UPDATE projects SET user_id = {OWNER_NUM} WHERE id = {PROJECT_NUM}" | \
#  heroku pg:psql --app master-bestpractices

desc 'Change owner of PROJECT. rake change_owner -- PROJECT_NUM NEW_OWNER_NUM'
task change_owner: :environment do
  # Project.update_all_badge_percentages(Criteria.keys)
  ARGV.shift # Drop rake task name
  ARGV.shift # Drop '--'
  project_number = Integer(ARGV[0]) # Raise exceptions on non-integers
  user_number = Integer(ARGV[1])
  # Retrieve and print current project/owner
  project = Project.find(project_number.to_i)
  puts("Project      ##{project.id} #{project.name}")
  old_owner_id = project.user_id
  old_owner_name = User.find_by(id: old_owner_id)&.name
  puts("Former owner ##{old_owner_id} #{old_owner_name}")
  # Retrieve and print new owner info
  new_owner_id = user_number.to_i
  new_owner_record = User.find(new_owner_id)
  new_owner_name = new_owner_record.name
  puts("New owner    ##{new_owner_id} #{new_owner_name}")
  # Cause change
  if project.user_id == new_owner_id
    puts('No change, nothing done')
  else
    project.user_id = new_owner_id
    project.save!
    puts("Revert with: rake change_owner -- #{project.id} #{old_owner_id}")
  end
  # Rake tries to run the arguments which is annoying.
  # ARGV.shift; ARGV.shift doesn't work, so just flat-out exit(0).
  exit(0)
end

# Use this if the badge rules change.  This will email those who
# gain/lose a badge because of the changes.
desc 'Run to recalculate all badge percentages for all projects'
task update_all_badge_percentages: :environment do
  Project.update_all_badge_percentages(Criteria.keys)
end

desc 'Run to recalculate higher-level badge percentages for all projects'
task update_all_higher_level_badge_percentages: :environment do
  Project.update_all_badge_percentages(Criteria.keys - ['0'])
end

# To change the email encryption keys:
# Set EMAIL_ENCRYPTION_KEY_OLD to old key,
# set EMAIL_ENCRYPTION_KEY and EMAIL_BLIND_INDEX_KEY to new key, and run this.
# THIS ASSUMES THAT THE DATABASE IS QUIESCENT (e.g., it's temporarily
# unavailable to users).  If you don't like that assumption, put this
# within a transaction, but you'll pay a performance price.
# Note: You *CAN* re-invoke this if a previous pass only went partway;
# we loop over all users, but ignore users where the rekey doesn't work.
desc 'Rekey (change keys) of email addresses'
task rekey: :environment do
  old_key = [ENV.fetch('EMAIL_ENCRYPTION_KEY_OLD', nil)].pack('H*')
  User.find_each do |u|
    # rubocop:disable Style/RedundantBegin
    begin
      u.rekey(old_key) # Raises exception if there's a CipherError.
      Rails.logger.info "Rekeyed email address of user id #{u.id}"
      u.save! if u.email.present?
    rescue OpenSSL::Cipher::CipherError
      Rails.logger.info "Cannot rekey user #{u.id}"
    end
    # rubocop:enable Style/RedundantBegin
  end
end

Rake::Task['test:run'].enhance ['test:features']

# Modify system so 'test' forces runnning of system tests
task test: 'test:system'

# This is the task to run every day, e.g., to record statistics
# Configure your system (e.g., Heroku) to run this daily.  If you're using
# Heroku, see: https://devcenter.heroku.com/articles/scheduler
desc 'Run daily tasks used in any tier, e.g., record daily statistics'
task daily: :environment do
  ProjectStat.create!
  day_for_monthly = (ENV['BADGEAPP_DAY_FOR_MONTHLY'] || '5').to_i
  Rake::Task['monthly'].invoke if Time.now.utc.day == day_for_monthly
end

# Run this task to email a limited set of reminders to inactive projects
# that do not have a badge.
# Configure your system (e.g., Heroku) to run this daily.  If you're using
# Heroku, see: https://devcenter.heroku.com/articles/scheduler
# rubocop:disable Style/Send
desc 'Send reminders to the oldest inactive project badge entries.'
task reminders: :environment do
  puts 'Sending inactive project reminders. List of reminded project ids:'
  p ProjectsController.send :send_reminders
  true
end
# rubocop:enable Style/Send

# rubocop:disable Style/Send
desc 'Send monthly announcement of passing projects'
task monthly_announcement: :environment do
  puts 'Sending monthly announcement. List of reminded project ids:'
  p ProjectsController.send :send_monthly_announcement
  true
end
# rubocop:enable Style/Send

desc 'Run monthly tasks (called from "daily")'
task monthly: %i[environment monthly_announcement fix_use_gravatar] do
end

# Send a mass email, subject MASS_EMAIL_SUBJECT, body MASS_EMAIL_BODY.
# If you set MASS_EMAIL_WHERE, only matching records will be emailed.
# We send *separate* emails for each user, so that users won't be able
# to learn of each other's email addresses.
# We do *NOT* try to localize, for speed.
desc 'Send a mass email (e.g., a required GDPR notification)'
task :mass_email do
  subject = ENV.fetch('MASS_EMAIL_SUBJECT', nil)
  body = ENV.fetch('MASS_EMAIL_BODY', nil)
  where_condition = ENV['MASS_EMAIL_WHERE'] || 'true'
  raise if !subject || !body

  User.where(where_condition).find_each do |u|
    UserMailer.direct_message(u, subject, body).deliver_now
    Rails.logger.info "Mass notification sent to user id #{u.id}"
  end
end

# Run this task periodically if we want to test the
# install-badge-dev-environment script
desc 'check that install-badge-dev-environment works'
task :test_dev_install do
  puts 'Updating test-dev-install branch'
  sh <<-TEST_BRANCH_SHELL
    git checkout test-dev-install
    git merge --no-commit main
    git checkout HEAD circle.yml
    git commit -a -s -m "Merge main into test-dev-install"
    git push origin test-dev-install
    git checkout main
  TEST_BRANCH_SHELL
end

# JavaScript tests end up running .chromedriver-helper, which is downloaded
# and cached.  Update the cached version.
desc 'Update webdrivers/chromedriver'
if Rails.env.production? || Rails.env == 'fake_production'
  task :update_chromedriver do
    puts 'Skipping update_chromedriver (libraries not available).'
  end
else
  task :update_chromedriver do
    require 'webdrivers'
    # force-upgrade to the latest version of chromedriver
    # Note: This is *NOT* Rails' "update" method, ignore Rails/SaveBang.
    Webdrivers::Chromedriver.update
  end
end

# Run some slower tests. Doing this on *every* automated test run would be
# slow things down, and the odds of them being problems are small enough
# that the slowdown is less worthwhile.  Also, some of the tests (like the
# CORS tests) can interfere with the usual test setups, so again, they
# aren't worth running in the "normal" automated tests run on each commit.
desc 'Run slow tests (e.g., CORS middleware stack location)'
task :slow_tests do
  # Test CORS library middleware stack location check in environments.
  # Because of the way it works, Rack::Cors *must* be first in the Rack
  # middleware stack, as documented here: https://github.com/cyu/rack-cors
  # This test verifies this precondition, because it'd be easy to
  # accidentally cause this assumption to fail as code is changed and
  # gems are added or updated.
  # This is a slow test (we bring up a whole environment).
  %w[production development test].each do |environment|
    command = "RAILS_ENV=#{environment} rake middleware"
    result = IO.popen(command).readlines.grep(/^use /).first.chomp
    Kernel.abort("Misordered #{command}") unless result == 'use Rack::Cors'
  end
end

# Search for & print matching email address.
# Presumes we are in a Rails environment
def real_search_email(email)
  # Trivial email validation check. This isn't sophisticated, this is primarily
  # to prevent swapping the email & name fields when calling search_user.
  raise ArgumentError unless /.+@.+/.match?(email)

  results = User.where(email: email).select('id, name, encrypted_email, encrypted_email_iv').pluck(
    :id, :name
  )
  puts results
end

# Search for a given user email address.
desc 'Search for users with given email (for GDPR requests)'
task search_email: :environment do
  ARGV.shift # Drop rake task name
  ARGV.shift if ARGV[0] == '--' # Skip garbage
  email = ARGV[0]
  puts "Searching for email '#{email}'; matching ids and names are:"
  real_search_email(email)
  puts 'End of results.'
  exit(0) # Work around rake
end

# Search for & print matching name.
# Presumes we are in a Rails environment
def real_search_name(name)
  name_downcase = name.downcase
  results = User.where('lower(name) LIKE ?', "%#{name_downcase}%")
                .select('id, name, encrypted_email, encrypted_email_iv')
                .pluck(:id, :name)
  puts results
end

# Search for a given user name.
# Note: This is slow, because we don't have an index for this.
# We instead must linerarly search the database.
# However, we only get 1-5 requests/month, the queries are from a
# trusted source, and speed isn't critical, so we haven't bothered.
# We use a case-mapped search and LIKE, to greatly reduce the risk of
# failing to find the user name.
desc 'Search for users with given case-insensitive name (for GDPR requests)'
task search_name: :environment do
  ARGV.shift # Drop rake task name
  ARGV.shift if ARGV[0] == '--' # Skip garbage
  name = ARGV[0]
  puts "Searching for name '#{name}' ignoring case; matching ids and names are:"
  real_search_name(name)
  puts 'End of results.'
  exit(0) # Work around rake
end

# Search for a given user name AND email address.
desc 'Search for users with NAME and EMAIL (for GDPR requests)'
task search_user: :environment do
  ARGV.shift # Drop rake task name
  ARGV.shift if ARGV[0] == '--' # Skip garbage
  name = ARGV[0]
  email = ARGV[1]
  puts "Searching for name '#{name}', email #{email} (ignoring case for both)"
  real_search_name(name)
  real_search_email(email)
  puts 'Done.'
  exit(0) # Work around rake
end

desc 'Update Database list of bad passwords from raw-bad-passwords-lowercase'
task update_bad_password_db: :environment do
  BadPassword.force_load
end

desc 'Update SVG badge images from shields.io'
task :update_badge_images do
  # require 'Paleta'
  sh 'curl -o app/assets/images/badge_static_passing.svg ' \
     'https://img.shields.io/badge/openssf_best_practices-passing-4c1'
  sh 'curl -o app/assets/images/badge_static_silver.svg ' \
     'https://img.shields.io/badge/openssf_best_practices-silver-c0c0c0'
  sh 'curl -o app/assets/images/badge_static_gold.svg https://img.shields.io/badge/openssf_best_practices-gold-ffd700'
  100.times do |percent|
    # scale "color" to be greener as we approach passing, to provide a
    # visual indication of progress for those who can see color
    color = Paleta::Color.new(:hsl, (percent * 0.45) + 15, 85, 43).hex
    puts(color)
    sh "curl -o app/assets/images/badge_static_#{percent}.svg " \
       'https://img.shields.io/badge/openssf_best_practices-in_progress_' \
       "#{percent}%25-#{color}"
  end
  # TODO: Capture widths
  sh <<-CAPTURE_WIDTHS
    file='app/assets/images/badge_static_widths.txt'
    echo '{' > "$file"
    for level in passing silver gold $(seq 0 99)
    do
      width=$(grep -Eo 'width="[0-9]*"' app/assets/images/badge_static_"$level".svg | head -1 | tr -dc '0-9')
      echo "  '${level}': ${width}," >> "$file"
    done
    echo '}' >> "$file"
  CAPTURE_WIDTHS
  puts <<-REMINDERS
    Reminders:
    Extract app/assets/images/badge_static_widths.txt into app/models/badge.rb
    cp -p app/assets/images/badge_static_passing.svg \
          test/fixtures/files/badge-passing.svg
    cp -p app/assets/images/badge_static_silver.svg \
          test/fixtures/files/badge-silver.svg
    cp -p app/assets/images/badge_static_gold.svg \
          test/fixtures/files/badge-gold.svg
    cp -p app/assets/images/badge_static_88.svg \
          test/fixtures/files/badge-88.svg
  REMINDERS
end
