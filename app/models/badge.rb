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

  # rubocop:disable Metrics/CyclomaticComplexity
  def create_svg(percentage)
    passing = percentage == 100
    width = passing ? '192' : '204'
    fill = passing ? '#97CA00' : '#dfb317'
    d1 = passing ? 'M103 0h89v20h-89z' : 'M103 0h101v20H103z'
    d2 = passing ? 'M0 0h192v20H0z' : 'M0 0h204v20H0z'
    x = passing ? '145.5' : '152.5'
    text = passing ? 'passing 100%' : "in progress #{percentage}%"
    svg_template(width, fill, d1, d2, x, text)
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
  def svg_template(width, fill, d1, d2, x, text)
    <<-ENDOFSTRING.squish
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width}"
    height="20"><linearGradient id="b" x2="0" y2="100%"><stop
    offset="0" stop-color="#bbb" stop-opacity=".1"/><stop
    offset="1" stop-opacity=".1"/></linearGradient><mask
    id="a"><rect width="#{width}" height="20" rx="3"
    fill="#fff"/></mask><g mask="url(#a)"><path fill="#555"
    d="M0 0h103v20H0z"/><path fill="#{fill}"
    d="#{d1}"/><path fill="url(#b)"
    d="#{d2}"/></g><g fill="#fff" text-anchor="middle"
    font-family="DejaVu Sans,Verdana,Geneva,sans-serif"
    font-size="11"><text x="51.5" y="15" fill="#010101"
    fill-opacity=".3">cii best practices</text><text x="51.5"
    y="14">cii best practices</text><text x="#{x}" y="15"
    fill="#010101" fill-opacity=".3">#{text}</text><text
    x="#{x}" y="14">#{text}</text></g></svg>
    ENDOFSTRING
  end
  # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists
end
