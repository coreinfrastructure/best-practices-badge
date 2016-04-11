# frozen_string_literal: true
class Criteria
  ATTRIBUTES = CriteriaHash.reduce([]) do |attributes, criterion|
    attributes | criterion[1].keys
  end.map(&:to_sym).freeze
  ACCESSORS = (%i(name) + ATTRIBUTES).freeze
  # self.instantiate_from_yaml

  include ActiveModel::Model
  attr_accessor(*ACCESSORS)

  class << self
    include Enumerable
    alias length count
    alias size count

    def active
      reject(&:future?)
    end

    def all
      memoize.to_a
    end

    def each
      # Each method is required for Criteria to use class-level Enumerable mixin
      memoize.each do |criterion|
        yield criterion
      end
      self
    end

    def find_by_name(input)
      find { |criterion| criterion.name.to_s == input.to_s }
    end

    def instantiate_from_yaml
      # @instantiating = true
      CriteriaHash.each do |criterion|
        new({ name: criterion[0].to_sym }.merge(criterion[1]))
      end
      # memoize
      # binding.pry
      # @instantiating = false
    end

    def keys
      all.map(&:name)
    end

    def memoize
      @criteria ||= ObjectSpace.each_object(self)
    end
  end

  # Instance Methods

  def initialize(*parameters)
    # Criteria.instantiate_from_yaml unless @criteria || @instantiating
    @criteria = false # Erase memoization
    # binding.pry
    super(*parameters)
    freeze
  end

  def future?
    category == 'FUTURE'
  end

  def met_url_required?
    # Is a URL required in the justification to be enough with met?
    met_url_required == true
  end

  def na_allowed?
    na_allowed == true
  end

  def to_s
    name.to_s
  end
end
