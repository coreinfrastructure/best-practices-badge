# frozen_string_literal: true

class TextValidator < ActiveModel::EachValidator
  ENCODING_MESSAGE =  'must be have a valid  UTF-8 encoding and ' \
                      'no invalid control characters'
  INVALID_CONTROL = /[\x01-\x08\x0b\x0c\x0e-\x1f]/
  def text_acceptable?(value)
    return true if value.nil?
    return false unless value.valid_encoding?
    (value =~ INVALID_CONTROL).nil?
  end

  def validate_each(record, attribute, value)
    return if text_acceptable?(value)
    record.errors.add attribute, (options[:message] || ENCODING_MESSAGE)
  end
end
