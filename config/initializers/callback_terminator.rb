# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Rails 5 changed how callback chains are interpreted. See:
# https://blog.bigbinary.com/2016/02/13/
# rails-5-does-not-halt-callback-chain-when-false-is-returned.html
# In short, returning false DOES NOT stop the chain any more.
# Rendering or redirecting still halts the chain (in development, this
# produces a "Filter chain halted as .... rendered or redirected" message).
# If you want to halt the chain, but do not render or redirect,
# use this to halt the chain: throw(:abort)

# Set the following to true to restore the old semantics,
# but this is not supported in Rails 5.2+:
# ActiveSupport.halt_callback_chains_on_return_false = true
