# Guess project name from URLs.

# frozen_string_literal: true

class NameFromUrlDetective < Detective
  INPUTS = [:repo_url, :project_url]
  OUTPUTS = [:name]

  # rubocop:disable Metrics/MethodLength
  def analyze(_evidence, current)
    project_url = current[:project_url]
    # repo_files = current[:repo_files]
    @results = {}

    name_in_project_url_domain =
      %r{\Ahttps?://(www\.)?([A-Za-z0-9-]+)\.([A-Za-z0-9._-]*)/?\Z}
    name_in_project_url_tail = %r{[^/]/([A-Za-z0-9._-]*)/?\Z}

    if project_url.present?
      finding = name_in_project_url_domain.match(project_url)
      if finding && finding[2].present?
        @results[:name] =
          { value: finding[2], confidence: 1,
            explanation: "The project URL's domain name suggests this." }
      else
        finding = name_in_project_url_tail.match(project_url)
        if finding
          @results[:name] =
            { value: finding[1], confidence: 1,
              explanation: "The project URL's tail suggests this." }
        end
      end
    end
    @results
  end
end
