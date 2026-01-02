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
  # Initialize the middleware.
  # @param app [Object] The Rack application to wrap
  # @param interval_seconds [Integer] Interval in seconds between compactions.
  #   Defaults to ENV['BADGEAPP_GC_COMPACT_MINUTES'] converted to seconds,
  #   or 7200 seconds (120 minutes) if ENV not set.
  def initialize(app, interval_seconds: (ENV['BADGEAPP_GC_COMPACT_MINUTES'] || 120).to_i * 60)
    @app = app
    @mutex = Mutex.new
    @interval = interval_seconds
    @last_compact_time = Time.zone.now # Last time it was *scheduled*
    @first_call = true
    # Pre-allocate the method object once during initialization.
    # This creates a "callable" that points to the compact method
    # without needing a new lambda per request.
    @compact_memory_callback = method(:compact_memory)
    # Log initialization at WARN level so it appears even with WARN log level
    Rails.logger.warn "GcCompactMiddleware initialized: interval=#{@interval}s"
  end

  def call(env)
    response = @app.call(env)
    schedule_compact_if_it_is_time(env)
    response
  end

  private

  # Thread-safe check to schedule a gc compact if it's time to do it.
  # The mutex ensures thread-safe read of @last_compact_time and @first_call.
  def schedule_compact_if_it_is_time(env)
    @mutex.synchronize do
      # Log first call only, to make it easy to verify that the
      # gc middleware is actually being invoked.
      if @first_call
        Rails.logger.warn 'GcCompactMiddleware: First request received'
        @first_call = false
      end
      # Is it time to schedule compaction?
      if Time.zone.now - @last_compact_time >= @interval
        # It's time to schedule compaction. Record compaction time.
        @last_compact_time = Time.zone.now
        schedule_compact_memory(env)
      end
    end
  end

  # Schedule the memory compaction.
  # The "scheduling" is adding information to rack's env
  # requesting that rack later call the routine to compact memory.
  def schedule_compact_memory(env)
    Rails.logger.warn 'GcCompactMiddleware: Scheduling compaction'
    # Schedule compaction to happen later, using rack.after_reply.
    # We do it this way to minimize new memory allocations.
    if (after_reply = env['rack.after_reply'])
      after_reply << @compact_memory_callback
    else
      # We create a new array here each time, because
      # other middleware might manipulate this array further.
      env['rack.after_reply'] = [@compact_memory_callback]
    end
  end

  # Actually perform garbage collection compaction.
  # This is the method that is scheduled to run later.
  def compact_memory
    Rails.logger.warn 'GC.compact started'
    GC.compact
    Rails.logger.warn 'GC.compact completed'
  end
end
