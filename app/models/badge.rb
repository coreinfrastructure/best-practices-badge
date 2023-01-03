# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'set'

# rubocop: disable Metrics/ClassLength
class Badge
  ACCEPTABLE_PERCENTAGES = (0..99).to_a.freeze
  ACCEPTABLE_LEVELS = %w[passing silver gold].freeze

  # Make this a set so we can quickly determine if an input is "valid?"
  ACCEPTABLE_INPUTS = (
    ACCEPTABLE_PERCENTAGES + ACCEPTABLE_LEVELS
  ).to_set.freeze

  # These are copied from app/assets/images/badge_static_widths.txt
  # after running 'rake update_badge_images'.
  # We very rarely change the static images in a way that affects widths,
  # so it's simpler to just copy the information into the source code here.
  # As a style recommendation remove the comma from the last entry.
  # rubocop:disable Lint/SymbolConversion
  BADGE_WIDTHS = {
    'passing': 184,
    'silver': 172,
    'gold': 166,
    '0': 228,
    '1': 228,
    '2': 228,
    '3': 228,
    '4': 228,
    '5': 228,
    '6': 228,
    '7': 228,
    '8': 228,
    '9': 228,
    '10': 234,
    '11': 234,
    '12': 234,
    '13': 234,
    '14': 234,
    '15': 234,
    '16': 234,
    '17': 234,
    '18': 234,
    '19': 234,
    '20': 234,
    '21': 234,
    '22': 234,
    '23': 234,
    '24': 234,
    '25': 234,
    '26': 234,
    '27': 234,
    '28': 234,
    '29': 234,
    '30': 234,
    '31': 234,
    '32': 234,
    '33': 234,
    '34': 234,
    '35': 234,
    '36': 234,
    '37': 234,
    '38': 234,
    '39': 234,
    '40': 234,
    '41': 234,
    '42': 234,
    '43': 234,
    '44': 234,
    '45': 234,
    '46': 234,
    '47': 234,
    '48': 234,
    '49': 234,
    '50': 234,
    '51': 234,
    '52': 234,
    '53': 234,
    '54': 234,
    '55': 234,
    '56': 234,
    '57': 234,
    '58': 234,
    '59': 234,
    '60': 234,
    '61': 234,
    '62': 234,
    '63': 234,
    '64': 234,
    '65': 234,
    '66': 234,
    '67': 234,
    '68': 234,
    '69': 234,
    '70': 234,
    '71': 234,
    '72': 234,
    '73': 234,
    '74': 234,
    '75': 234,
    '76': 234,
    '77': 234,
    '78': 234,
    '79': 234,
    '80': 234,
    '81': 234,
    '82': 234,
    '83': 234,
    '84': 234,
    '85': 234,
    '86': 234,
    '87': 234,
    '88': 234,
    '89': 234,
    '90': 234,
    '91': 234,
    '92': 234,
    '93': 234,
    '94': 234,
    '95': 234,
    '96': 234,
    '97': 234,
    '98': 234,
    '99': 234
  }.freeze
  # rubocop:enable Lint/SymbolConversion

  attr_accessor :svg

  class << self
    # Class methods
    include Enumerable

    # Create Badge static values as we need them.
    def [](level)
      raise ArgumentError unless valid?(level)

      @badges ||= {}
      @badges[level] ||= new(level)
    end

    def all
      create_all unless @badges&.length == 103
      ACCEPTABLE_INPUTS.map { |level| self[level] }
    end

    def create_all
      @badges = {}
      ACCEPTABLE_INPUTS.each { |level| @badges[level] = new(level) }
    end

    def each
      all.each { |badge| yield badge }
      self
    end

    def valid?(level)
      ACCEPTABLE_INPUTS.include?(level)
    end
  end

  # Instance methods
  def initialize(level)
    raise ArgumentError unless self.class.valid?(level)

    @svg = load_svg(level)
  end

  def to_s
    svg
  end

  private

  def load_svg(level)
    File.read("app/assets/images/badge_static_#{level}.svg")
  end
end
# rubocop: enable Metrics/ClassLength
