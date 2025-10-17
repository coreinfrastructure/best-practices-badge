# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Middleware to periodically run GC.compact to reduce memory fragmentation.
# Compaction runs after response is sent to client (no user-facing latency).
# Frequency controlled by BADGEAPP_GC_COMPACT_MINUTES (default: 120 minutes).
# Note that this class has a singleton instance
class GcCompactMiddleware
  def initialize(app)
    @app = app
    @last_compact_time = Time.zone.now
    @interval = (ENV['BADGEAPP_GC_COMPACT_MINUTES'] || 120).to_i * 60
    @mutex = Mutex.new
  end

  def call(env)
    response = @app.call(env)
    schedule_compact(env) if time_to_compact?
    response
  end

  private

  def time_to_compact?
    Time.zone.now - @last_compact_time >= @interval
  end

  # This method handles multiple threads. Here's how:
  # 1. Multiple threads see time_to_compact? returns true
  # 2. They all call schedule_compact(env)
  # 3. First thread acquires mutex, updates @last_compact_time, and
  #    sets scheduled = true
  # 4. Other threads wait, then see the time is already updated, and skip
  #    scheduling
  # 5. Only one compaction gets scheduled
  def schedule_compact(env)
    scheduled = false
    @mutex.synchronize do
      if Time.zone.now - @last_compact_time >= @interval
        @last_compact_time = Time.zone.now
        scheduled = true
      end
    end
    (env['rack.after_reply'] ||= []) << -> { compact } if scheduled
  end

  def compact
    Rails.logger.info 'GC.compact started'
    GC.compact
    Rails.logger.info 'GC.compact completed'
  end
end
