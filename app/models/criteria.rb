# frozen_string_literal: true

class Criteria
  ACCESSORS = %i[
    name category level future
    rationale autofill
    met_suppress na_suppress unmet_suppress
    met_justification_required met_url_required met_url
    na_allowed na_justification_required
    major minor unmet
  ].freeze

  LOCALE_ACCESSORS = %i[
    description details met_placeholder unmet_placeholder na_placeholder
  ].freeze

  include ActiveModel::Model
  attr_accessor(*ACCESSORS)

  class << self
    # Class methods
    include Enumerable

    def [](key)
      instantiate if @criteria.blank?
      @criteria[key]
    end

    def active(level)
      instantiate if @criteria.blank?
      @active ||= {}
      @active[level] ||= @criteria[level].values.reject(&:future?)
    end

    def all
      instantiate if @criteria.blank?
      @criteria.values.map(&:keys).flatten.uniq
    end

    def each
      instantiate if @criteria.blank?
      @criteria.each { |level| yield level }
    end

    def instantiate
      # Creates class instances on first use and after reload! in rails console
      @criteria = {}
      CriteriaHash.each do |level, level_hash|
        @criteria[level] = {}
        level_hash.each do |criterion|
          name = criterion[0].to_sym
          @criteria[level][name] =
            new({ name: name, level: level }.merge(criterion[1]))
        end
      end
    end

    def keys
      instantiate if @criteria.blank?
      @criteria.keys
    end

    def to_h
      CriteriaHash
    end
  end

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

  def description
    return nil unless I18n.exists?(
      "criteria.#{level}.#{name}.description", :en
    )
    I18n.t("criteria.#{level}.#{name}.description")
  end

  def details
    return nil unless I18n.exists?(
      "criteria.#{level}.#{name}.details", :en
    )
    I18n.t("criteria.#{level}.#{name}.details")
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
