# frozen_string_literal: true

# Load in known-bad passwords; they're stored in a .gz (compressed) file.
# This only takes 0.2 seconds to load around 100,000 lines, so we just do
# this as part of system initialization instead of loading it later.
# Check for membership looks like: BadPasswordSet.include?(value.downcase)

require 'zlib'

BadPasswordSet = {}.to_set
Zlib::GzipReader.open('raw-bad-passwords-lowercase.txt.gz') do |gz|
  gz.each_line do |line|
    BadPasswordSet.add(line.chomp.downcase.freeze)
  end
end
BadPasswordSet.freeze
