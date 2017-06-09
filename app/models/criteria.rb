# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/ClassLength
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

    # This returns an array of all levels where a particular criterion of
    # a given name is present.
    def get_levels(criterion)
      instantiate if @criteria.blank?
      @criteria_levels[criterion]
    end

    def instantiate
      # Creates class instances on first use and after reload! in rails console
      CriteriaHash.each do |level, level_hash|
        level_hash.each do |criterion|
          name = criterion[0].to_sym
          ((@criteria ||= {})[level] ||= {})[name] =
            new({ name: name, level: level }.merge(criterion[1]))
          ((@criteria_levels ||= {})[name] ||= []).append(level)
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

  def description
    key = "criteria.#{level}.#{name}.description"
    return nil unless I18n.exists?(key)
    I18n.t(key)
  end

  def details
    get_text_if_exists(:details)
  end

  delegate :present?, to: :details, prefix: true

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

  def should?
    category == 'SHOULD'
  end

  def suggested?
    category == 'SUGGESTED'
  end

  delegate :to_s, to: :name

  private

  # This method is used to grab text that is the same regardless of
  # critera level. For example details of a criterion is almost always the
  # same across criteria levels.  This routine searches the current level
  # and all lower levels for a given text snippet until it is found.  If
  # it doesn't exist, nil is returned.
  def get_text_if_exists(field)
    return nil unless field.in? LOCALE_ACCESSORS
    Criteria.get_levels(name).reverse.each do |l|
      next if l.to_i > level.to_i
      t_key = "criteria.#{l}.#{name}.#{field}"
      return I18n.t(t_key) if I18n.exists?(t_key)
    end
    nil
  end
end
