# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class PasswordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless BadPasswordSet.include?(value.downcase)
    record.errors.add attribute,
                      options[:message] || 'is a well-known (bad) password'
  end
end
