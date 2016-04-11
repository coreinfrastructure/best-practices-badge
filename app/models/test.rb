# frozen_string_literal: true
class Test
  include ActiveModel::Model
  attr_accessor :name

  class << self
    include Enumerable

    def all
      ObjectSpace.each_object(self).to_a
    end

    def each
      ObjectSpace.each_object(self).each do |object|
        yield object
      end
      self
    end

    def find_by_name(input)
      find { |object| object.name.to_s == input.to_s }
    end

    def instantiate
      new(name: 'Alice')
      new(name: 'Bob')
    end
  end

  # Instance Methods

  def initialize(*parameters)
    super(*parameters)
    freeze
  end

  delegate :to_s, to: :name
end
