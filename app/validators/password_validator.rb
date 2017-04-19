# frozen_string_literal: true

class PasswordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless BadPasswordSet.include?(value.downcase)
    record.errors.add attribute,
                      options[:message] || 'is a well-known (bad) password'
  end
end
