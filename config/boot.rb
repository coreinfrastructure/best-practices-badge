# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

if ENV['RAILS_ENV'] == 'development'
  require 'bootsnap'
  Bootsnap.setup(
    # Path to your cache
    cache_dir:            'tmp/cache',
    # This should be set to whatever evaluates your current working environment,
    # e.g. RACK_ENV, RAILS_ENV, etc
    development_mode:     ENV['RAILS_ENV'] == 'development',
    # Should we optimize the LOAD_PATH with a cache?
    load_path_cache:      true,
    # Sets `RubyVM::InstructionSequence.compile_option =
    #   { trace_instruction: false }`
    # Should compile Ruby code into ISeq cache?
    compile_cache_iseq:   true,
    # Should compile YAML into a cache?
    compile_cache_yaml:   true
  )
end
