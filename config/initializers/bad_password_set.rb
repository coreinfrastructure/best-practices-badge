# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# We have a .gz (compressed) file of known-bad passwords (about 100,000).
# At one time we always loaded them into memory, while it only took
# 0.2 seconds to load around 100,000 lines, it took over 8MB of memory.
# So the list has been moved to the database instead.

# Here's how we *used* to do it.
# Check for membership looks like: BadPasswordSet.include?(value.downcase)
# require 'zlib'
#
# BadPasswordSet = {}.to_set
# Zlib::GzipReader.open('raw-bad-passwords-lowercase.txt.gz') do |gz|
#   gz.each_line do |line|
#     BadPasswordSet.add(line.chomp.downcase.freeze)
#   end
# end
# BadPasswordSet.freeze
