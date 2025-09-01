# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Register Terser compressor for asset pipeline
# This allows us to use config.assets.js_compressor = :terser
require 'terser'
Sprockets.register_compressor 'application/javascript', :terser, Terser::Compressor
