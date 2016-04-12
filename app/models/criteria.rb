# frozen_string_literal: true
# rubocop:disable Rails/FindEach
class Criteria
  ATTRIBUTES = CriteriaHash.reduce([]) do |attributes, criterion|
    attributes | criterion[1].keys
  end.map(&:to_sym).freeze
  ACCESSORS = (%i(name) + ATTRIBUTES).freeze

  include ActiveModel::Model
  attr_accessor(*ACCESSORS)

  class << self
    # Class methods
    include Enumerable

    def active
      reject(&:future?)
    end

    def all
      @criteria ||= ObjectSpace.each_object(self).to_a
    end

    def each
      all.each do |criterion|
        yield criterion
      end
      self
    end

    def find_by_name(input)
      @find_by_name ||= {}
      @find_by_name[input.to_s] ||= find do |criterion|
        criterion.to_s == input.to_s
      end
    end

    def instantiate_from_yaml
      @criteria = nil
      CriteriaHash.each do |criterion|
        new({ name: criterion[0].to_sym }.merge(criterion[1]))
      end
      all # This memoizes result to prevent garbage collection of instances
    end

    def keys
      all.map(&:name)
    end

    alias length count
  end

  # Instance methods

  def future?
    future == true
  end

  def initialize(*parameters)
    super(*parameters)
    freeze
  end

  def met_url
    nil
  end

  def met_url_required?
    # Is a URL required in the justification to be passing with met?
    met_url_required == true
  end

  def na_allowed?
    na_allowed == true
  end

  def na_placeholder
    nil
  end

  def na_suppress
    nil
  end

  delegate :to_s, to: :name
end
