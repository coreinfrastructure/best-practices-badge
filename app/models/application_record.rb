# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Returns the table name for CDN key computation.
  # Used with Fastly CDN for cache invalidation.
  # Based on:
  # https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/
  # active_record/surrogate_key.rb
  # @return [String] the table name for this model
  def table_key
    self.class.table_name
  end

  # Returns a unique record key for CDN cache invalidation.
  # Combines table name and record ID for Fastly surrogate keys.
  # @return [String] the unique record key in format "table_name/id"
  def record_key
    "#{table_key}/#{id}"
  end
end
