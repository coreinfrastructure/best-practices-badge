# Guess project name from URLs.

# frozen_string_literal: true

class NameFromUrlDetective < Detective
  INPUTS = [:repo_url, :project_homepage_url]
  OUTPUTS = [:name]

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def analyze(_evidence, current)
    project_homepage_url = current[:project_homepage_url]
    repo_url = current[:repo_url]
    @results = {}

    name_in_project_homepage_url_domain =
      %r{\Ahttps?://(www\.)?([A-Za-z0-9-]+)\.([A-Za-z0-9._-]*)/?\Z}
    name_in_url_tail = %r{[^/]/([A-Za-z0-9._-]*)/?\Z}

    if project_homepage_url.present?
      finding = name_in_project_homepage_url_domain.match(project_homepage_url)
      if finding && finding[2].present?
        @results[:name] =
          { value: finding[2], confidence: 1,
            explanation: "The project URL's domain name suggests this." }
      else
        finding = name_in_url_tail.match(project_homepage_url)
        if finding
          @results[:name] =
            { value: finding[1], confidence: 1,
              explanation: "The project URL's tail suggests this." }
        end
      end
    end
    if !@results.key?(:name) && repo_url.present?
      finding = name_in_url_tail.match(repo_url)
      if finding
        @results[:name] =
          { value: finding[1], confidence: 1,
            explanation: "The repo URL's tail suggests this." }
      end
    end
    @results
  end
end
