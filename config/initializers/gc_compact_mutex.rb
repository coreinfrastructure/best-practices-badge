# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Global mutex for GC compaction scheduling.
# This MUST be a global variable to survive Rails class reloading in
# development/test environments. If we used an instance variable in the
# middleware class, Rails would create a NEW mutex each time it reloads
# GcCompactMiddleware, breaking thread synchronization and potentially
# allowing multiple threads to schedule compaction simultaneously.
#
# The mutex ensures only one thread can check and schedule GC compaction
# at a time, preventing race conditions in the interval timing logic.
# rubocop:disable Style/GlobalVars
$gc_compact_mutex = Mutex.new
# rubocop:enable Style/GlobalVars
