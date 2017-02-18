json.merge! @project.attributes
if @project.show_entry_license?
  json.project_entry_license 'CC-BY-3.0+'
  json.project_entry_attribution ('Please credit '.html_safe +
                                  @project.user.name +
                                  ' and the CII Best Practices badge' +
                                  ' contributors.')
end
