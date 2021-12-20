# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class PasswordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless BadPassword.exists?(forbidden: value.downcase)

    record.errors.add attribute,
                      options[:message] ||
                      I18n.t('error_messages.known_bad_password')
  end
end
