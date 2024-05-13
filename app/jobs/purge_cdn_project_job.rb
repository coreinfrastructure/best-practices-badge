# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class PurgeCdnProjectJob < ApplicationJob
  queue_as :default

  # Rails supports passing the project record directly as "project".
  # However, this is inefficient; we really only need the record_key
  # (which we use as the cdn_badge_key).
  def perform(cdn_badge_key)
    # Send purge message to CDN
    FastlyRails.purge_by_key cdn_badge_key
  end
end
