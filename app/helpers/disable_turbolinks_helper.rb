# frozen_string_literal: true

module DisableTurbolinksHelper
  # Modify HTML text to disable turbolinks when necessary.
  # We do this instead of trying to fix the underlying text because
  # it's a specific workaround for a specific library.
  def disable_turbolinks(html)
    # Disable turbolinks for all hrefs referring to /project_stats.
    # We allow some variation to reduce the risk of accidentally not
    # fixing links that should be fixed.
    result = html.gsub(
      %r{(\shref\s*=\s*["'][^"']*\/project_stats)},
      ' data-turbolinks="false"\1'
    )
    # If it was safe before, it's still safe after this transform.
    # rubocop:disable Rails/OutputSafety
    html.html_safe? ? result.html_safe : result
    # rubocop:enable Rails/OutputSafety
  end
end
