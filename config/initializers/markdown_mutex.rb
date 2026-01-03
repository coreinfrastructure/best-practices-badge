# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Global mutex for Redcarpet thread-safety.
# This MUST be a global variable to survive Rails class reloading in
# development/test environments. If we used a module constant, Rails would
# create a NEW mutex each time it reloads ProjectsHelper, breaking
# thread synchronization and causing race conditions.
#
# Redcarpet (a C extension) has thread-safety bugs at two levels:
# 1. Instance level: Need separate Redcarpet::Markdown instances per thread
# 2. Global state level: Need serialized access even with separate instances
#
# This mutex provides the global serialization. Thread-local storage in
# ProjectsHelper provides the per-thread instances.
# rubocop:disable Style/GlobalVars
$markdown_mutex = Mutex.new
# rubocop:enable Style/GlobalVars
