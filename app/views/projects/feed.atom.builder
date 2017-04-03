# Generate /feed view.
# If you add new fields to be displayed, be sure to modify
# the calling controller(s) to retrieve those fields.  Typically the
# callers will only retrieve the fields necessary for display.
#
# Disable cache for Rails.env.test?. There is a bug in the
# test framework that doesn't handle caching correctly in tests.
cache_if (!Rails.env.test? && !@projects.empty?),
         ['feed-index', @projects[0]] do
  atom_feed do |feed|
    feed.title('CII Best Practices BadgeApp Updated Projects')
    feed.updated(@projects[0].updated_at) unless @projects.empty?

    @projects.each do |project|
      cache_if !Rails.env.test?, project do
        feed.entry(project) do |entry|
          entry.title project.name.presence || '(Name Unknown)'
          status = "<p><b>#{project.badge_level.titleize}: " \
                   "#{project.badge_percentage}%</b></p>"
          url = project.homepage_url.presence || project.repo_url
          link = "<p><a href='#{url}'>#{url}</a></p>"
          description = markdown(project.description || '')
          content = status + link + description
          entry.content(type: 'html') { entry.cdata! content }
          entry.author { |author| author.name(project.user_display_name) }
        end
      end
    end
  end
end
