# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# The "fix_markdown" script is too eager to make changes, so we'll
# warn about using it for now.
desc 'Fix common markdown errors in all non-temporary markdown files'
# rubocop:disable Metrics/BlockLength
task :fix_markdown_dontuse do
  require 'open3'

  # Find all markdown files, excluding temporary files (starting with ,)
  markdown_files =
    Dir.glob('**/*.md').reject do |file|
      File.basename(file).start_with?(',')
    end

  if markdown_files.empty?
    puts 'No markdown files found.'
    exit 0
  end

  puts "Found #{markdown_files.size} markdown files to fix"
  puts

  total_fixes = 0
  fixed_files = 0
  failed_files = []

  markdown_files.sort.each do |file|
    print "Processing: #{file} ... "

    # Run the fix_markdown.rb script on each file
    stdout, stderr, status = Open3.capture3('ruby', 'script/fix_markdown.rb', '--quiet', file)

    if status.success?
      # Extract number of fixes from output
      if stdout =~ /Fixed (\d+) markdown issues/
        fixes = Regexp.last_match(1).to_i
        if fixes.positive?
          puts "✓ (#{fixes} fixes)"
          total_fixes += fixes
          fixed_files += 1
        else
          puts '✓ (no changes needed)'
        end
      else
        puts '✓'
      end
    else
      puts '✗ FAILED'
      failed_files << file
      warn "  Error: #{stderr}" unless stderr.empty?
    end
  end

  # Summary
  puts
  puts '=' * 60
  puts 'Summary:'
  puts "  Files processed: #{markdown_files.size}"
  puts "  Files modified: #{fixed_files}"
  puts "  Total fixes: #{total_fixes}"

  if failed_files.any?
    puts "  Failed files: #{failed_files.size}"
    puts
    puts 'Failed files:'
    failed_files.each { |file| puts "  - #{file}" }
    exit 1
  end

  puts
  puts '✓ All markdown files processed successfully!'
  puts
  puts 'Next steps:'
  puts '  1. Review changes with: git diff'
  puts '  2. Run: rake markdownlint'
  puts '  3. Manually fix any remaining errors'
end
# rubocop:enable Metrics/BlockLength
