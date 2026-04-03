# frozen_string_literal: true

# Compare Chief's proposals with and without SecurityInsightsDetective
# for a badge project that already exists in the database.
#
# Usage:
#   rails runner script/si_detective_compare_by_project_id.rb PROJECT_ID
#
# PROJECT_ID: numeric badge project ID whose repo_url points to the project
# you want to test (e.g. a project pointing to github.com/openfga/openfga).
#
# Output shows three sections:
#   ONLY WITH SI   - criteria proposed only when SI detective is active
#   CHANGED BY SI  - criteria proposed by both, but SI produces higher confidence
#   ONLY WITHOUT   - criteria proposed only when SI detective is absent (sanity check)

project_id = ARGV[0]&.to_i
unless project_id&.positive?
  warn 'Usage: rails runner script/si_detective_compare_by_project_id.rb PROJECT_ID'
  exit 1
end

project = Project.find(project_id)
puts "Project: #{project.name} (#{project.repo_url})"
puts

client_factory = ->(token = nil) { Octokit::Client.new(access_token: token) }

def run_chief(project, client_factory, pool)
  chief = Chief.new(project, client_factory)
  # Temporarily swap ALL_DETECTIVES so Chief uses our custom pool
  Chief.send(:remove_const, :ALL_DETECTIVES)
  Chief.const_set(:ALL_DETECTIVES, pool.freeze)
  chief.propose_changes
ensure
  # Always restore the original constant
  Chief.send(:remove_const, :ALL_DETECTIVES) rescue nil # rubocop:disable Style/RescueModifier
  Chief.const_set(:ALL_DETECTIVES, (pool.include?(SecurityInsightsDetective) ?
    pool : pool + [SecurityInsightsDetective]).freeze)
end

def status_label(val)
  { CriterionStatus::MET => 'Met', CriterionStatus::UNMET => 'Unmet',
    CriterionStatus::NA => 'N/A', CriterionStatus::UNKNOWN => '?' }[val] || val.to_s
end

original_pool = Chief::ALL_DETECTIVES.dup
pool_without_si = original_pool.reject { |d| d == SecurityInsightsDetective }

puts '--- Running Chief WITHOUT SecurityInsightsDetective ---'
without_si = run_chief(project, client_factory, pool_without_si)
puts "  #{without_si.size} proposals"

# Restore properly before second run
Chief.send(:remove_const, :ALL_DETECTIVES) rescue nil # rubocop:disable Style/RescueModifier
Chief.const_set(:ALL_DETECTIVES, original_pool.freeze)

puts '--- Running Chief WITH SecurityInsightsDetective ---'
with_si = run_chief(project, client_factory, original_pool)
puts "  #{with_si.size} proposals"

# Restore for real
Chief.send(:remove_const, :ALL_DETECTIVES) rescue nil # rubocop:disable Style/RescueModifier
Chief.const_set(:ALL_DETECTIVES, original_pool.freeze)

puts
puts '=' * 60

only_with = with_si.reject { |k, _| without_si.key?(k) }
only_without = without_si.reject { |k, _| with_si.key?(k) }
changed = with_si.select do |k, v|
  without_si.key?(k) && v[:confidence] != without_si[k][:confidence]
end

if only_with.any?
  puts "\nONLY WITH SI (#{only_with.size} new proposals):"
  only_with.sort_by { |k, v| [-v[:confidence], k.to_s] }.each do |k, v|
    puts format('  conf %-4s  %-8s  %s', v[:confidence], status_label(v[:value]), k)
    puts "         #{v[:explanation]}" if v[:explanation].present?
  end
else
  puts "\nONLY WITH SI: (none)"
end

if changed.any?
  puts "\nCHANGED BY SI (#{changed.size} higher-confidence proposals):"
  changed.sort_by { |k, _| k.to_s }.each do |k, v|
    puts "  #{k}: conf #{without_si[k][:confidence]} -> #{v[:confidence]}  #{status_label(v[:value])}"
  end
else
  puts "\nCHANGED BY SI: (none)"
end

if only_without.any?
  puts "\nONLY WITHOUT SI (#{only_without.size} — sanity check, should be empty):"
  only_without.each { |k, _| puts "  #{k}" }
else
  puts "\nONLY WITHOUT SI: (none — good)"
end
