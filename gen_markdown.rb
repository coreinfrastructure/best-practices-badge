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
FullCriteriaHash = YAML.load_file('criteria/criteria.yml')
CriteriaText = YAML.load_file('config/locales/en.yml')['en']['criteria']['0']

def print_file(filename)
  File.open(filename, 'r') do |file|
    while (line = file.gets)
      puts line
    end
  end
end

def show_details(key)
  return unless CriteriaText[key].key?('details')

  print "<dt><i>Details</i>:<dt> <dd>#{CriteriaText[key]['details']}</dd>"
end

def show_extra(criterion)
  return unless criterion.key?('rationale')

  print "<dt><i>Rationale</i>:<dt> <dd>#{criterion['rationale']}</dd>"
end

# rubocop:disable Metrics/AbcSize,Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
def puts_criterion(key, criterion)
  print "\n<li><a name=\"#{key}\"></a>"
  print '(Future criterion) ' if criterion.key?('future')
  print CriteriaText[key]['description']
  # print " (N/A #{criterion.key?('na_allowed') ? '' : 'not '}allowed.)"
  print ' (N/A allowed.)' if criterion.key?('na_allowed')
  if criterion.key('met_justification_required')
    print ' (Justification required for "Met".)'
  end
  if criterion.key?('na_justification_required')
    print ' (Justification required for "N/A".)'
  end
  print ' (URL required for "met".)' if criterion.key?('met_url_required')
  print " <sup>[<a href=\"##{key}\">#{key}</a>]</sup>"
  if CriteriaText[key].key?('details') || criterion.key?('rationale')
    print '<dl>' # Put details and rationale in a detail list
    show_details(key)
    show_extra(criterion)
    print '</dl>'
  end
  puts '</li>'
end
# rubocop:enable Metrics/AbcSize,Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

# Generate results
$stdout.reopen('doc/criteria.md', 'w') || abort('Cannot write')
print_file('doc/criteria-header.markdown')
FullCriteriaHash['0'].each do |major, major_value|
  puts ''
  puts "### #{major}"
  major_value.each do |minor, criteria|
    puts ''
    puts "<b><i>#{minor}</i></b>" # Force HTML interpretation
    puts ''
    puts '<ul>'
    criteria.each do |key, criterion|
      puts_criterion(key, criterion)
    end
    puts '</ul>'
  end
end
print_file('doc/criteria-footer.markdown')
