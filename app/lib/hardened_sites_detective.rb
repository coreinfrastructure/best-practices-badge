# Determine if project sites support HTTPS

# frozen_string_literal: true

class HardenedSitesDetective < Detective
  XCTO = 'x-content-type-options'

  # The sole allowed value for the X-Content-Type-Options header.
  NOSNIFF = 'nosniff'

  # All of the security-hardening headers that need to be present to pass.
  CHECK =
    [
      'content-security-policy', XCTO, 'x-frame-options', 'x-xss-protection'
    ].freeze
  MET =
    {
      value: 'Met', confidence: 3,
      explanation: 'Found all required security hardening headers.'
    }.freeze
  UNMET_MISSING =
    {
      value: 'Unmet', confidence: 5,
      explanation: 'One or more of the required security hardening headers '\
        'is missing.'
    }.freeze
  UNMET_NOSNIFF =
    {
      value: 'Unmet', confidence: 5,
      explanation: 'X-Content-Type-Options was not set to "nosniff".'
    }.freeze

  INPUTS = %i(repo_url homepage_url).freeze
  OUTPUTS = [:hardened_site_status].freeze

  # Check the given list of header hashes to make sure that all expected
  # keys are present.
  def security_fields_present?(headers_list)
    result = true
    headers_list.each do |headers|
      result &&= CHECK.reduce(true) { |acc, elem| acc & headers.key?(elem) }
    end
    result
  end

  # Perform GET request, and return either an empty hash (if the GET is
  # unsuccessful) or a hash of the response header keys and values.
  def get_headers(evidence, url)
    response = evidence.get(url)
    response.nil? ? {} : response[:meta]
  end

  # Inspect the X-Content-Type-Options headers and make sure that they have the
  # only allowed value.
  def check_nosniff?(headers_list)
    result = true
    headers_list.each do |response_headers|
      xcto = response_headers[XCTO]
      result &&= xcto.nil? ? false : xcto.casecmp(NOSNIFF).zero?
    end
    result
  end

  # Internal method that does the inspection work for the 'analyze' method.
  def check_urls(evidence, homepage_url, repo_url)
    @results = {}
    if homepage_url.present? && repo_url.present?
      homepage_headers = get_headers(evidence, homepage_url)
      repo_headers = get_headers(evidence, repo_url)
      hardened = security_fields_present?([homepage_headers, repo_headers])
      @results[:hardened_site_status] = hardened ? MET : UNMET_MISSING
      hardened ||= check_nosniff?([homepage_headers, repo_headers])
      @results[:hardened_site_status] = UNMET_NOSNIFF unless hardened
    end
    @results
  end

  # Analyze the home page and repository URLs to make sure that security
  # hardening headers are returned in the headers of a GET response.
  def analyze(evidence, current)
    check_urls(evidence, current[:homepage_url], current[:repo_url])
  end
end
