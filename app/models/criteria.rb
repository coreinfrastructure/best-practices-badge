# frozen_string_literal: true

# rubocop:disable Rails/FindEach
class Criteria
  ACCESSORS = %i[
    name category future
    description details rationale
    met_suppress na_suppress unmet_suppress
    met_justification_required met_url_required met_url
    na_allowed na_justification_required
    autofill met_placeholder unmet_placeholder na_placeholder
    major minor unmet
  ].freeze

  include ActiveModel::Model
  attr_accessor(*ACCESSORS)

  class << self
    # Class methods
    include Enumerable

    def [](key)
      instantiate if @criteria.blank?
      @criteria[key.to_sym]
    end

    def active
      @active ||= reject(&:future?)
    end

    def all
      instantiate if @criteria.blank?
      @criteria.values
    end

    def each
      all.each { |criterion| yield criterion }
      self
    end

    def instantiate
      # Creates class instances on first use and after reload! in rails console
      @criteria = {}
      CriteriaHash.each do |criterion|
        name = criterion[0].to_sym
        @criteria[name] = new({ name: name }.merge(criterion[1]))
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

  def met_justification_required?
    met_justification_required == true
  end

  def must?
    category == 'MUST'
  end

  def na_allowed?
    na_allowed == true
  end

  def na_justification_required?
    na_justification_required == true
  end

  delegate :present?, to: :details, prefix: true

  def should?
    category == 'SHOULD'
  end

  def suggested?
    category == 'SUGGESTED'
  end

  delegate :to_s, to: :name
end
