# frozen_string_literal: true

# rubocop:disable Rails/FindEach, Metrics/ClassLength
class Badge
  ACCEPTABLE_PERCENTAGES = (0..99).map { |num| num }.freeze
  ACCEPTABLE_LEVELS = %w[passing silver gold].freeze

  ACCEPTABLE_INPUTS = (ACCEPTABLE_PERCENTAGES + ACCEPTABLE_LEVELS).freeze

  attr_accessor :svg

  class << self
    # Class methods
    include Enumerable

    def [](level)
      valid? level
      @badges ||= {}
      @badges[level] ||= new(level)
    end

    def all
      create_all unless @badges && @badges.length == 103
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
      raise ArgumentError unless level.in? ACCEPTABLE_INPUTS
    end
  end

  # Instance methods
  def initialize(level)
    self.class.valid? level
    @svg = create_svg(level)
  end

  def to_s
    svg
  end

  private

  def create_svg(level)
    # svg badges generated from http://shields.io/
    return in_progress_svg(level) if level.is_a?(Integer)
    return passing_svg if level == 'passing'
    return silver_svg if level == 'silver'
    gold_svg
  end

  def in_progress_svg(percentage)
    color = Paleta::Color.new(:hsl, percentage * 0.45 + 15, 85, 43).hex
    <<-ENDOFSTRING.squish
    <svg xmlns="http://www.w3.org/2000/svg" width="204"
    height="20"><linearGradient id="b" x2="0" y2="100%"><stop
    offset="0" stop-color="#bbb" stop-opacity=".1"/><stop
    offset="1" stop-opacity=".1"/></linearGradient><mask
    id="a"><rect width="204" height="20" rx="3"
    fill="#fff"/></mask><g mask="url(#a)"><path fill="#555"
    d="M0 0h103v20H0z"/><path fill="##{color}" d="M103
    0h101v20H103z"/><path fill="url(#b)" d="M0
    0h204v20H0z"/></g><g fill="#fff" text-anchor="middle"
    font-family="DejaVu Sans,Verdana,Geneva,sans-serif"
    font-size="11"><text x="51.5" y="15" fill="#010101"
    fill-opacity=".3">cii best practices</text><text x="51.5"
    y="14">cii best practices</text><text x="152.5" y="15"
    fill="#010101" fill-opacity=".3">in progress
    #{percentage}%</text><text x="152.5" y="14">in progress
    #{percentage}%</text></g></svg>
    ENDOFSTRING
  end

  def passing_svg
    <<-ENDOFSTRING.squish
    <svg xmlns="http://www.w3.org/2000/svg" width="154"
    height="20"><linearGradient id="b" x2="0" y2="100%"><stop
    offset="0" stop-color="#bbb" stop-opacity=".1"/><stop
    offset="1" stop-opacity=".1"/></linearGradient><mask
    id="a"><rect width="154" height="20" rx="3"
    fill="#fff"/></mask><g mask="url(#a)"><path fill="#555"
    d="M0 0h103v20H0z"/><path fill="#4c1" d="M103
    0h89v20h-89z"/><path fill="url(#b)" d="M0
    0h192v20H0z"/></g><g fill="#fff" text-anchor="middle"
    font-family="DejaVu Sans,Verdana,Geneva,sans-serif"
    font-size="11"><text x="51.5" y="15" fill="#010101"
    fill-opacity=".3">cii best practices</text><text x="51.5"
    y="14">cii best practices</text><text x="127.5" y="15"
    fill="#010101" fill-opacity=".3">passing</text>
    <text x="127.5" y="14">passing</text></g></svg>
    ENDOFSTRING
  end

  def silver_svg
    <<-ENDOFSTRING.squish
    <svg xmlns="http://www.w3.org/2000/svg" width="142"
    height="20"><linearGradient id="b" x2="0" y2="100%"><stop
    offset="0" stop-color="#bbb" stop-opacity=".1"/><stop
    offset="1" stop-opacity=".1"/></linearGradient><mask
    id="a"><rect width="142" height="20" rx="3"
    fill="#fff"/></mask><g mask="url(#a)"><path fill="#555"
    d="M0 0h103v20H0z"/><path fill="#C0C0C0" d="M103
    0h101v20H103z"/><path fill="url(#b)" d="M0
    0h204v20H0z"/></g><g fill="#fff" text-anchor="middle"
    font-family="DejaVu Sans,Verdana,Geneva,sans-serif"
    font-size="11"><text x="51.5" y="15" fill="#010101"
    fill-opacity=".3">cii best practices</text><text x="51.5"
    y="14">cii best practices</text><text fill="#fefefe"
    fill-opacity=".7" x="121.5" y="15">silver</text><text
    fill="#000" x="121.5" y="14">silver</text></g></svg>
    ENDOFSTRING
  end

  def gold_svg
    <<-ENDOFSTRING.squish
    <svg xmlns="http://www.w3.org/2000/svg" width="136"
    height="20"><linearGradient id="b" x2="0" y2="100%"><stop
    offset="0" stop-color="#bbb" stop-opacity=".1"/><stop
    offset="1" stop-opacity=".1"/></linearGradient><mask
    id="a"><rect width="136" height="20" rx="3"
    fill="#fff"/></mask><g mask="url(#a)"><path fill="#555"
    d="M0 0h103v20H0z"/><path fill="#ffd700" d="M103
    0h89v20h-89z"/><path fill="url(#b)" d="M0
    0h192v20H0z"/></g><g fill="#fff" text-anchor="middle"
    font-family="DejaVu Sans,Verdana,Geneva,sans-serif"
    font-size="11"><text x="51.5" y="15" fill="#010101"
    fill-opacity=".3">cii best practices</text><text x="51.5"
    y="14">cii best practices</text><text fill="#fefefe"
    fill-opacity=".7" x="118.5" y="15">gold</text><text
    fill="#000" x="118.5" y="14">gold</text></g></svg>
    ENDOFSTRING
  end
end
