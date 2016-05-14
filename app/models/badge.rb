# frozen_string_literal: true
# rubocop:disable Rails/FindEach
class Badge
  attr_accessor :svg

  class << self
    # Class methods
    include Enumerable

    def [](percentage)
      valid? percentage
      @badges ||= {}
      @badges[percentage] ||= new(percentage)
    end

    def all
      create_all unless @badges && @badges.length == 101
      (0..100).map { |percentage| self[percentage] }
    end

    def create_all
      @badges = {}
      (0..100).each { |num| @badges[num] = new(num) }
    end

    def each
      all.each { |badge| yield badge }
      self
    end

    def valid?(percentage)
      raise ArgumentError unless percentage.is_a?(Fixnum) &&
                                 (0..100).cover?(percentage)
    end
  end

  # Instance methods
  def initialize(percentage)
    self.class.valid? percentage
    @svg = create_svg(percentage)
  end

  def to_s
    svg
  end

  private

  def create_svg(percentage)
    # svg badges generated from http://shields.io/
    return passing_svg if percentage == 100
    in_progress_svg(percentage)
  end

  # rubocop:disable Metrics/MethodLength
  def in_progress_svg(percentage)
    <<-ENDOFSTRING.squish
    <svg xmlns="http://www.w3.org/2000/svg" width="204"
    height="20"><linearGradient id="b" x2="0" y2="100%"><stop
    offset="0" stop-color="#bbb" stop-opacity=".1"/><stop
    offset="1" stop-opacity=".1"/></linearGradient><mask
    id="a"><rect width="204" height="20" rx="3"
    fill="#fff"/></mask><g mask="url(#a)"><path fill="#555"
    d="M0 0h103v20H0z"/><path fill="#dfb317" d="M103
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
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def passing_svg
    <<-ENDOFSTRING.squish
    <svg xmlns="http://www.w3.org/2000/svg" width="192"
    height="20"><linearGradient id="b" x2="0" y2="100%"><stop
    offset="0" stop-color="#bbb" stop-opacity=".1"/><stop
    offset="1" stop-opacity=".1"/></linearGradient><mask
    id="a"><rect width="192" height="20" rx="3"
    fill="#fff"/></mask><g mask="url(#a)"><path fill="#555"
    d="M0 0h103v20H0z"/><path fill="#97CA00" d="M103
    0h89v20h-89z"/><path fill="url(#b)" d="M0
    0h192v20H0z"/></g><g fill="#fff" text-anchor="middle"
    font-family="DejaVu Sans,Verdana,Geneva,sans-serif"
    font-size="11"><text x="51.5" y="15" fill="#010101"
    fill-opacity=".3">cii best practices</text><text x="51.5"
    y="14">cii best practices</text><text x="145.5" y="15"
    fill="#010101" fill-opacity=".3">passing
    100%</text><text x="145.5" y="14">passing
    100%</text></g></svg>
    ENDOFSTRING
  end
  # rubocop:enable Metrics/MethodLength
end
