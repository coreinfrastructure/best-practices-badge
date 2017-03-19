json.cache! @project, expires_in: 10.minutes do
  json.partial! 'project', project: @project
end
