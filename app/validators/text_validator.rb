# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class TextValidator < ActiveModel::EachValidator
  INVALID_CONTROL = /[\x01-\x08\x0b\x0c\x0e-\x1f]/.freeze
  def text_acceptable?(value)
    return true if value.nil?
    return false unless value.valid_encoding?

    (value =~ INVALID_CONTROL).nil?
  end

  def validate_each(record, attribute, value)
    return if text_acceptable?(value)

    record.errors.add attribute, (options[:message] ||
                                  I18n.t('error_messages.valid_text'))
  end
end
