# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/ClassLength
class Criteria
  include ActiveModel::Model
  include LevelConversion # Shared level name/number conversion

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

  FIELDS_TO_OMIT = %w[description details rationale autofill].freeze

  attr_accessor(*ACCESSORS)

  class << self
    # Class methods
    include Enumerable

    # Retrieves criteria for a specific level.
    # @param key [String, Symbol] the criteria level key
    # @return [Hash] criteria hash for the specified level
    def [](key)
      instantiate if @criteria.blank?
      @criteria[key]
    end

    # Returns active (non-future) criteria for a specific level.
    # @param level [String, Integer] the badge level
    # @return [Array<Criteria>] array of active criteria for the level
    def active(level)
      instantiate if @criteria.blank?
      @active ||= {}
      @active[level] ||= @criteria[level].values.reject(&:future?)
    end

    # Returns all unique criteria names across all levels.
    # @return [Array<Symbol>] array of all criteria names
    def all
      instantiate if @criteria.blank?
      @criteria.values.map(&:keys).flatten.uniq
    end

    def each
      instantiate if @criteria.blank?
      @criteria.each { |level| yield level }
    end

    def each_value
      instantiate if @criteria.blank?
      @criteria.each_value { |level_data| yield level_data }
    end

    # No longer needed. Instead use "Project::LEVEL_IDS.each"
    # def each_key
    #   instantiate if @criteria.blank?
    #   @criteria.each_key { |level_key| yield level_key }
    # end

    # Returns all levels where a particular criterion is present.
    # @param criterion [String, Symbol] the criterion name
    # @return [Array<String>] array of levels containing this criterion
    def get_levels(criterion)
      instantiate if @criteria.blank?
      @criteria_levels[criterion]
    end

    # Creates class instances from CriteriaHash on first use.
    # Populates @criteria and @criteria_levels class variables.
    # @return [void]
    def instantiate
      # Creates class instances on first use and after reload! in rails console
      CriteriaHash.each do |level, level_hash|
        level_hash.each do |criterion|
          name = criterion.first.to_sym
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

    # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    def for_js
      CriteriaHash.deep_dup.each do |level, criteria_set|
        criteria_set.each do |criterion, fields|
          fields.delete_if { |k, _v| k.in? FIELDS_TO_OMIT }
          translations = {}
          I18n.available_locales.each do |locale|
            I18n.t(".criteria.#{level}.#{criterion}").each_key do |k|
              next if k.to_s.in? FIELDS_TO_OMIT

              translations[k.to_s] = {} unless translations.key?(k.to_s)
              translations[k.to_s][locale.to_s] =
                I18n.t(".criteria.#{level}.#{criterion}.#{k}", locale: locale)
            end
          end
          fields.update(translations)
        end
      end
    end
    # rubocop:enable Metrics/AbcSize,Metrics/MethodLength
  end

  # Returns the localized description for this criterion.
  # @return [String, nil] HTML-safe description text or nil if not found
  def description
    key = "criteria.#{level}.#{name}.description"
    return unless I18n.exists?(key)

    # Descriptions only come from trusted data source, so we can safely disable
    # rubocop:disable Rails/OutputSafety
    I18n.t(key).html_safe
    # rubocop:enable Rails/OutputSafety
  end

  # Returns the localized details for this criterion.
  # @return [String, nil] HTML-safe details text or nil if not found
  def details
    get_text_if_exists(:details)
  end

  delegate :present?, to: :details, prefix: true

  # Checks if this criterion is marked as future (not yet active).
  # @return [Boolean] true if criterion is for future implementation
  def future?
    future == true
  end

  # Creates a new Criteria instance and freezes it for immutability.
  # @param parameters [Array] initialization parameters
  def initialize(*parameters)
    super
    # Precompute symbol names before freezing (performance optimization)
    @status_symbol = :"#{name}_status"
    @justification_symbol = :"#{name}_justification"
    freeze
  end

  # Checks if a URL is required in the justification for 'Met' status.
  # @return [Boolean] true if URL is required for Met justification
  def met_url_required?
    met_url_required == true
  end

  # Checks if justification text is required for 'Met' status.
  # @return [Boolean] true if justification is required for Met status
  def met_justification_required?
    met_justification_required == true
  end

  def met_justification_or_url_required?
    met_justification_required? || met_url_required?
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

  # Returns the database field symbol for this criterion's status
  # Precomputed during initialization to avoid string concatenation on every render
  # @return [Symbol] e.g., :description_good_status
  attr_reader :status_symbol

  # Returns the database field symbol for this criterion's justification
  # Precomputed during initialization to avoid string concatenation on every render
  # @return [Symbol] e.g., :description_good_justification
  attr_reader :justification_symbol

  private

  # This method is used to grab text that is the same regardless of
  # criteria level. For example details of a criterion is almost always the
  # same across criteria levels.  This routine searches the current level
  # and all lower levels for a given text snippet until it is found.  If
  # it doesn't exist, nil is returned.
  def get_text_if_exists(field)
    return unless field.in? LOCALE_ACCESSORS

    Criteria.get_levels(name).reverse_each do |l|
      # Compare levels using mapping, not .to_i
      next if level_higher?(l, level)

      t_key = "criteria.#{l}.#{name}.#{field}"
      # Disable HTML output safety. I18n translations are internal data
      # and are considered a trusted source.
      # rubocop:disable Rails/OutputSafety
      return I18n.t(t_key).html_safe if I18n.exists?(t_key)
      # rubocop:enable Rails/OutputSafety
    end
    nil
  end

  # Returns true if level1 is higher than level2
  def level_higher?(level1, level2)
    level_num1 = level_to_number(level1)
    level_num2 = level_to_number(level2)
    level_num1 > level_num2
  end
end
# rubocop:enable Metrics/ClassLength
