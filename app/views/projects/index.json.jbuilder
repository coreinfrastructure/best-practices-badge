json.array!(@projects) do |project|
  json.merge! project.attributes
  json.url project_url(project, format: :json)
end
