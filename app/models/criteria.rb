# frozen_string_literal: true
class Criteria
  ATTRIBUTES = CriteriaHash.reduce([]) do |attributes, criterion|
    attributes | criterion[1].keys
  end.map(&:to_sym).freeze
  ACCESSORS = (%i(name) + ATTRIBUTES).freeze

  include ActiveModel::Model
  attr_accessor(*ACCESSORS)

  class << self
    include Enumerable
    alias length count
    alias size count

    # CriteriaHash is loaded during application initialization
    # from the criteria.yml YAML file. This instantiates all criteria:
    CriteriaHash.each do |criterion|
      Criteria.new({ name: criterion[0].to_sym }.merge(criterion[1]))
    end

    def active
      reject(&:future?)
    end

    def all
      ObjectSpace.each_object(self).to_a
    end

    def each
      # Each method is required for Criteria to use class-level Enumerable mixin
      ObjectSpace.each_object(self) do |criterion|
        yield criterion
      end
      self
    end

    def find_by_name(name)
      find { |criterion| criterion.name.to_s == name.to_s }
    end

    def keys
      all.map(&:name)
    end
  end

  # Instance Methods

  def initialize(*parameters)
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
end
