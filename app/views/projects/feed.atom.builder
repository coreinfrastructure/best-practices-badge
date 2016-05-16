atom_feed do |feed|
  feed.title('CII Best Practices BadgeApp Updated Projects')
  feed.updated(@projects[0].updated_at) unless @projects.empty?

  @projects.each do |project|
    feed.entry(project) do |entry|
      entry.title project.name.presence || '(Name Unknown)'
      status = "<p><b>#{project.badge_level.titleize}: " \
               "#{project.badge_percentage}%</b></p>"
      url = project.homepage_url.presence || project.repo_url
      link = "<p><a href='#{url}'>#{url}</a></p>"
      description = markdown(project.description || '')
      content = status + link + description
      entry.content(type: 'html') { entry.cdata! content }
      entry.author { |author| author.name(project.user_name) }
    end
  end
end
