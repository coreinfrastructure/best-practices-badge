# Show all projects in @projects as a single JSON file.

# We intentionally do *NOT* cache this result, since it's large
# (trying to cache it would probably evict other more important entries),
# we expect this request to be rare, and *any* change to *any* project
# entry would invalidate the cached result anyway.

# We also don't cache the individual entries. There are a lot of them,
# so caching all the individual entries might evict other entries
# that are more likely to be retrieved in the future.

json.array!(@projects) do |project|
  json.partial! 'project', project: project
end
