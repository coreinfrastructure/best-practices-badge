# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Rails 5 changed how callback chains are interpreted. See:
# https://blog.bigbinary.com/2016/02/13/
# rails-5-does-not-halt-callback-chain-when-false-is-returned.html
# For now, restore the old semantics, until we're confident that
# things work with the new semantics.

ActiveSupport.halt_callback_chains_on_return_false = true
