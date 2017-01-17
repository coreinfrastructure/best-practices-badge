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

def print_file(filename)
  File.open(filename, 'r') do |file|
    while (line = file.gets)
      puts line
    end
  end
  puts ''
end

def show_extra(key, header_text, criterion)
  return unless criterion.key?(key)
  print "<dt><i>#{header_text}</i>:<dt> <dd>#{criterion[key]}</dd>"
end

def puts_criterion(key, criterion)
  print "\n<li><a name=\"#{key}\"></a>"
  print '(Future criterion) ' if criterion.key?('future')
  print criterion['description']
  # print " (N/A #{criterion.key?('na_allowed') ? '' : 'not '}allowed.)"
  print ' (N/A allowed.)' if criterion.key?('na_allowed')
  print ' (URL required for "met".)' if criterion.key?('met_url_required')
  print " <sup>[<a href=\"\##{key}\">#{key}</a>]</sup>"
  print '<dl>' # Put details and rationale in a detail list
  show_extra('details', 'Details', criterion)
  show_extra('rationale', 'Rationale', criterion)
  puts '</dl></li>'
end

# Generate results
$stdout.reopen('doc/criteria-generated.md', 'w') || abort('Cannot write')
print_file('doc/criteria-header.markdown')
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
print_file('doc/criteria-footer.markdown')
