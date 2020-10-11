# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'set'

class Badge
  ACCEPTABLE_PERCENTAGES = (0..99).to_a.freeze
  ACCEPTABLE_LEVELS = %w[passing silver gold].freeze

  # Make this a set so we can quickly determine if an input is "valid?"
  ACCEPTABLE_INPUTS = (
    ACCEPTABLE_PERCENTAGES + ACCEPTABLE_LEVELS
  ).to_set.freeze

  WHITE_TEXT_SPECS = {
    color: 'fill="#000" ', shadow: 'fill="#fefefe" fill-opacity=".7"'
  }.freeze

  BLACK_TEXT_SPECS = {
    color: '', shadow: 'fill="#010101" fill-opacity=".3"'
  }.freeze

  IN_PROGRESS_SPECS = {
    width: 204, text: 'in progress', text_pos: 152.5,
    text_colors: BLACK_TEXT_SPECS
  }.freeze

  PASSING_SPECS = {
    width: 154, color: '#4c1', text: 'passing', text_pos: 127.5,
    text_colors: BLACK_TEXT_SPECS
  }.freeze

  SILVER_SPECS = {
    width: 142, color: '#C0C0C0', text: 'silver', text_pos: 121.5,
    text_colors: WHITE_TEXT_SPECS
  }.freeze

  GOLD_SPECS = {
    width: 136, color: '#ffd700', text: 'gold', text_pos: 118.5,
    text_colors: WHITE_TEXT_SPECS
  }.freeze

  BADGE_SPECS = {
    'in_progress' => IN_PROGRESS_SPECS, 'passing' => PASSING_SPECS,
    'silver' => SILVER_SPECS, 'gold' => GOLD_SPECS
  }.freeze

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

    @svg = create_svg(level)
  end

  def to_s
    svg
  end

  private

  def create_svg(level)
    # svg badges generated from http://shields.io/
    return badge_svg(BADGE_SPECS['in_progress'], level) if level.is_a?(Integer)

    badge_svg(BADGE_SPECS[level], nil)
  end

  # rubocop:disable Metrics/AbcSize
  def badge_svg(specs, percentage)
    color = specs[:color] ||
            '#' + Paleta::Color.new(:hsl, percentage * 0.45 + 15, 85, 43).hex
    text = percentage ? specs[:text] + " #{percentage}%" : specs[:text]
    <<-BADGE_AS_SVG.squish
    <svg xmlns="http://www.w3.org/2000/svg" width="#{specs[:width]}"
    height="20"><linearGradient id="b" x2="0" y2="100%"><stop offset="0"
    stop-color="#bbb" stop-opacity=".1"/><stop offset="1"
    stop-opacity=".1"/></linearGradient><mask id="a"><rect
    width="#{specs[:width]}" height="20" rx="3" fill="#fff"/></mask><g
    mask="url(#a)"><path fill="#555" d="M0 0h103v20H0z"/><path
    fill="#{color}" d="M103 0h#{specs[:width] - 103}v20H103z"/><path
    fill="url(#b)" d="M0 0h#{specs[:width]}v20H0z"/></g><g
    fill="#fff" text-anchor="middle"
    font-family="DejaVu Sans,Verdana,Geneva,sans-serif"
    font-size="11"><text x="51.5" y="15" fill="#010101"
    fill-opacity=".3">cii best practices</text><text x="51.5"
    y="14">cii best practices</text><text x="#{specs[:text_pos]}"
    y="15" #{specs[:text_colors][:shadow]}>#{text}</text><text
    #{specs[:text_colors][:color]}x="#{specs[:text_pos]}"
    y="14">#{text}</text></g></svg>
    BADGE_AS_SVG
  end
  # rubocop:enable Metrics/AbcSize
end
