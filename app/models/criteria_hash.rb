# frozen_string_literal: true

class CriteriaHash
  include Enumerable

  def initialize(criteria_hash)
    @criteria_hash = criteria_hash
    @criteria = {}
    @criteria_hash.each do |level, level_hash|
      @criteria[level] = {}
      level_hash.each do |criterion|
        name = criterion[0].to_sym
        @criteria[level][name] =
          Criterion.new({ name: name }.merge(criterion[1]))
      end
    end
  end

  def [](key)
    @criteria[key]
  end

  def all
    @criteria.values.map(&:keys).flatten.uniq
  end

  def each
    @criteria.each { |level| yield level }
  end

  def keys
    @criteria.keys
  end

  def level_to_h(level)
    @criteria_hash[level] if @criteria_hash.key?(level)
  end

  def to_h
    @criteria_hash
  end

  def values
    @criteria.values
  end
end
