# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'nokogiri'

# Parses OpenSSF Baseline HTML to extract criteria
class BaselineHtmlParser
  attr_reader :controls

  # HTML element names to stop at when parsing control content
  STOP_ELEMENTS = %w[h3 h4].freeze

  def initialize(html_content)
    @doc = Nokogiri::HTML(html_content)
    @controls = []
  end

  def parse
    # Find all h4 elements with IDs starting with "osps-"
    @doc.css('h4[id^="osps-"]').each do |h4|
      control = parse_control(h4)
      @controls << control if control
    end
    @controls
  end

  private

  # rubocop:disable Metrics/MethodLength
  def parse_control(h4_element)
    original_id = h4_element.text.strip
    return if original_id.empty?

    # Get all content until next h4 or h3
    content_elements = []
    current = h4_element.next_element
    while current && !STOP_ELEMENTS.include?(current.name)
      content_elements << current
      current = current.next_element
    end

    # Extract requirement, recommendation, and other details
    requirement = extract_requirement(content_elements)
    recommendation = extract_recommendation(content_elements)
    category = extract_category(h4_element)
    maturity_level = extract_maturity_level(content_elements)

    {
      original_id: original_id,
      field_name: id_to_field_name(original_id),
      category: category,
      requirement: requirement,
      recommendation: recommendation,
      maturity_level: maturity_level
    }
  end
  # rubocop:enable Metrics/MethodLength

  def extract_requirement(elements)
    elements.each do |el|
      next if el.text.exclude?('Requirement:')

      # Extract text after "Requirement:" removing the bold tag
      text = el.text.sub(/.*Requirement:\s*/, '').strip
      return clean_text(text)
    end
    nil
  end

  def extract_recommendation(elements)
    elements.each do |el|
      if el.text.include?('Recommendation:')
        text = el.text.sub(/.*Recommendation:\s*/, '').strip
        return clean_text(text)
      end
    end
    nil
  end

  def extract_category(h4_element)
    # Look for parent section to determine category
    parent_section = h4_element.ancestors('h2, h3').first
    return 'General' unless parent_section

    parent_section.text.strip
  end

  def extract_maturity_level(elements)
    # Look for "Control applies to:" and find maturity level
    elements.each do |el|
      next if el.text.exclude?('Control applies to:')

      # Look at next element which typically has the level list
      next_el = el.next_element
      next unless next_el&.name == 'ul'

      # Extract maturity levels from list items
      levels =
        next_el.css('li').filter_map do |li|
          text = li.text
          ::Regexp.last_match(1).to_i if text =~ /Maturity Level (\d+)/
        end
      return levels unless levels.empty?
    end
    [1] # Default to level 1
  end

  def id_to_field_name(original_id)
    # Transform OSPS-GV-03.01 to osps_gv_03_01
    original_id
      .downcase
      .tr('-', '_')
      .tr('.', '_')
  end

  def clean_text(text)
    # Remove extra whitespace, normalize line breaks
    text
      .gsub(/\s+/, ' ')
      .squeeze("\n")
      .strip
  end
end
