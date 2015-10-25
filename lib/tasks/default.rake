task(:default).clear.enhance %w(
  bundle
  test
  rubocop
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
