# frozen_string_literal: true
class Criteria
  class << self
    include Enumerable
    alias length count
    alias size count
  end

  # CriteriaHash is loaded during application initialization
  # from the criteria.yml YAML file

  ALL_CRITERIA = CriteriaHash.keys.map(&:to_sym).freeze
  ALL_ACTIVE_CRITERIA = ALL_CRITERIA.reject do |criterion|
    CriteriaHash[criterion]['category'] == 'FUTURE'
  end.freeze

  # Create recursive class methods for each criterion
  # Criteria name is a singleton class method on Criteria
  # Criteria attributes use an OpenStruct to respond to methods
  ALL_CRITERIA.each do |criterion|
    define_singleton_method(criterion) do
      OpenStruct.new(CriteriaHash[criterion])
    end
  end

  def self.each
    # Each method is required for Criteria to use class-level Enumerable mixin
    ALL_CRITERIA.each do |criterion|
      yield criterion
    end
    self
  end

  def self.keys
    ALL_CRITERIA
  end

  def self.to_h
    CriteriaHash
  end

  def self.criterion_category(criterion)
    # Is this criterion in the category MUST, SHOULD, or SUGGESTED?
    send(criterion).category
  end

  def self.na_allowed?(criterion)
    send(criterion).na_allowed
  end

  def self.met_url_required?(criterion)
    # Is a URL required in the justification to be enough with met?
    send(criterion).met_url_required
  end
end
