# frozen_string_literal: true
# rubocop:disable Rails/FindEach
class Criteria
  ATTRIBUTES = CriteriaHash.reduce([]) do |attributes, criterion|
    attributes | criterion[1].keys
  end.map(&:to_sym).freeze
  FUTURE_ATTRIBUTES = %i(met_url na_placeholder na_suppress).freeze
  ACCESSORS = (%i(name) + ATTRIBUTES + FUTURE_ATTRIBUTES).freeze

  include ActiveModel::Model
  attr_accessor(*ACCESSORS)

  class << self
    # Class methods
    include Enumerable

    def active
      @active ||= reject(&:future?)
    end

    def all
      # Creates class instances on first use and after reload! in rails console
      instantiate if @criteria.blank?
      @criteria
    end

    def each
      all.each { |criterion| yield criterion }
      self
    end

    def find_by_name(input)
      @find_by_name ||= {}
      @find_by_name[input.to_s] ||= find do |criterion|
        criterion.to_s == input.to_s
      end
    end

    def instantiate
      @criteria = []
      CriteriaHash.each do |criterion|
        @criteria << new({ name: criterion[0].to_sym }.merge(criterion[1]))
      end
    end

    def keys
      map(&:name)
    end

    def to_h
      CriteriaHash
    end
  end

  # Instance methods

  def future?
    future == true
  end

  def initialize(*parameters)
    super(*parameters)
    freeze
  end

  def met_url_required?
    # Is a URL required in the justification to be passing with met?
    met_url_required == true
  end

  def na_allowed?
    na_allowed == true
  end

  delegate :to_s, to: :name
end
