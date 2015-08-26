json.array!(@projects) do |project|
  json.extract! project, :id, :name, :description, :website, :license, :repo
  json.url project_url(project, format: :json)
end
