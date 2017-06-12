# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

Dir[Rails.root.join('lib', 'ext', '**', '*.rb')].each { |file| require file }
