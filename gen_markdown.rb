#!/usr/bin/env ruby
# Read criteria.yml and generate markdown with embedded HTML.

# frozen_string_literal: true

# It mostly generates HTML, so that any later reformat for line length
# is unaffected (markdown is primarily intended for human editing;
# its sensitivity to newlines can sometimes make it a little more work
# when it's generated.)

# Use the YAML library. It generates keys of type string, NOT keyword
require 'yaml'

# Load in entire criteria.yml, which keys off the major/minor groups
FullCriteriaHash = YAML.load_file('criteria.yml')

# Generate a warning so people are less likely to edit the generated result.
def puts_warning
  puts ''
  puts '[](DO-NOT-EDIT-this-is-GENERATED-from-criteria.yml)'
  puts ''
end

def print_file(filename)
  File.open(filename, "r") do |file|
    while line = file.gets
      puts line
    end
  end
  puts ''
end

def show_extra(key, header_text, criterion)
  return unless criterion.key?(key)
  print "<br><i>#{header_text}</i>: #{criterion[key]}"
end

def puts_criterion(key, criterion)
  print "\n<li><a name=\"#{key}\"></a>"
  print '(Future criterion) ' if criterion.key?('future')
  print criterion['description']
  # print " (N/A #{criterion.key?('na_allowed') ? '' : 'not '}allowed.)"
  print ' (N/A allowed.)' if criterion.key?('na_allowed')
  print ' (URL required for "met".)' if criterion.key?('met_url_required')
  show_extra('details', 'Details', criterion)
  show_extra('rationale', 'Rationale', criterion)
  puts " <sup>[<a href=\"\##{key}\">#{key}</a>]</sup></li>"
end

# Generate results
$stdout.reopen("doc/criteria-generated.md", "w") || abort('Cannot write')
puts_warning
print_file('doc/criteria-header.md')
FullCriteriaHash.each do |major, major_value|
  puts ''
  puts "### #{major}"
  major_value.each do |minor, criteria|
    puts ''
    puts "<i>#{minor}</i>" # Use <i>...</i> and <ul> to force HTML interp.
    puts ''
    puts '<ul>'
    criteria.each do |key, criterion|
      puts_criterion(key, criterion)
    end
    puts '</ul>'
  end
end
print_file('doc/criteria-footer.md')
