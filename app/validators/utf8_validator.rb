# frozen_string_literal: true
class UTF8Validator < ActiveModel::EachValidator
  ENCODING_MESSAGE = 'must be have a valid  UTF-8 encoding'
  def validate_each(record, attribute, value)
    return if value.valid_encoding?
    record.errors.add attribute, (options[:message] || ENCODING_MESSAGE )
  end
end
