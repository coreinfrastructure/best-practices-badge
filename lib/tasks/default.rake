task(:default).clear.enhance %w(
  bundle
  bundle_audit
  test
  rubocop
  markdownlint
  rails_best_practices
  brakeman
)

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
  sh 'bundle exec brakeman --quiet || true'
end

desc 'Run bundle if needed'
task :bundle do
  sh 'bundle check || bundle install'
end

desc 'Run bundle-audit - check for known vulnerabilities in dependencies'
task :bundle_audit do
  sh 'bundle exec bundle-audit update && bundle exec bundle-audit check'
end

desc 'Run markdownlint (mdl) - check for markdown problems'
task :markdownlint do
  style_file = 'config/markdown_style.rb'
  sh "find . -name '*.md' -exec bundle exec mdl -s #{style_file} {} +"
end
