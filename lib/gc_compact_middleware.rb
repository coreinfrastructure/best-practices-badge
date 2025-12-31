# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Middleware to periodically run the garbage collector's compactor
# using GC.compact to reduce memory fragmentation.
# Compaction is scheduled, not run directly, so that it
# runs after this response is sent to client. This may reduce
# user-facing latency.
# Frequency controlled by BADGEAPP_GC_COMPACT_MINUTES (default: 120 minutes).
# Note that this class has a singleton instance
class GcCompactMiddleware
  def initialize(app)
    @app = app
    @mutex = Mutex.new
    @interval = (ENV['BADGEAPP_GC_COMPACT_MINUTES'] || 120).to_i * 60
    @last_compact_time = Time.zone.now # Last time it was *scheduled*
    @first_call = true
    # Log initialization at WARN level so it appears even with WARN log level
    Rails.logger.warn "GcCompactMiddleware initialized: interval=#{@interval}s"
  end

  def call(env)
    response = @app.call(env)
    schedule_compact_if_time(env)
    response
  end

  private

  # Thread-safe check to see if it's time to schedule a gc compact, and
  # schedule it if that's true.
  # Uses mutex to ensure consistent read of @last_compact_time.
  def schedule_compact_if_time(env)
    @mutex.synchronize do
      # Log first call only, to verify middleware is actually being invoked
      # We do this check here, where we are *already* synchronizing the mutex,
      # so we don't grab the mutex twice.
      if @first_call
        Rails.logger.warn 'GcCompactMiddleware: First request received, middleware is active'
        @first_call = false
      end
      # Is it time to schedule compaction?
      if Time.zone.now - @last_compact_time >= @interval
        @last_compact_time = Time.zone.now
        schedule_compact(env)
      end
    end
  end

  # Schedule compaction to happen later. No need to grab the mutex;
  # we presume the caller has done so.
  def schedule_compact(env)
    Rails.logger.warn 'GcCompactMiddleware: Scheduling compaction'
    (env['rack.after_reply'] ||= []) << -> { compact }
  end

  # Actually perform garbage collection compaction.
  # This is the method that schedule_compact schedules to run.
  def compact
    Rails.logger.warn 'GC.compact started'
    GC.compact
    Rails.logger.warn 'GC.compact completed'
  end
end
