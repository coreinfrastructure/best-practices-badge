# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # table_key and record_key are used to compute CDN keys
  # Based on:
  # https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/
  # active_record/surrogate_key.rb
  def table_key
    self.class.table_name
  end

  def record_key
    "#{table_key}/#{id}"
  end
end
