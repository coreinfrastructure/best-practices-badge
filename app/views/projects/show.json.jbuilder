json.cache! @project, expires_in: 10.minutes do
  json.merge! @project.attributes
  json.project_entry_attribution ('Please credit '.html_safe +
                                  @project.user.name +
                                  ' and the CII Best Practices badge' +
                                  ' contributors.')
  if @project.show_entry_license?
    json.project_entry_license 'CC-BY-3.0+'
  else
    json.project_entry_license 'CC-BY-3.0'
  end
end
