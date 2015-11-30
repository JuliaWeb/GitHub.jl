############
# Starring #
############

function stargazers(repo; options...)
    results, page_data = gh_get_paged_json("/repos/$(name(repo))/stargazers"; options...)
    return map(Owner, results), page_data
end

function starred(user; options...)
    results, page_data = gh_get_paged_json("/users/$(name(user))/starred"; options...)
    return map(Repo, results), page_data
end

star(repo; options...) = gh_put("/user/starred/$(name(repo))"; options...)

unstar(repo; options...) = gh_delete("/user/starred/$(name(repo))"; options...)

############
# Watching #
############

function watchers(repo; options...)
    results, page_data = gh_get_paged_json("/repos/$(name(repo))/subscribers"; options...)
    return map(Owner, results), page_data
end

function watched(owner; options...)
    results, page_data = gh_get_paged_json("/users/$(name(owner))/subscriptions"; options...)
    return map(Repo, results), page_data
end

watch(repo; options...) = gh_put("/repos/$(name(repo))/subscription"; options...)

unwatch(repo; options...) = gh_delete("/repos/$(name(repo))/subscription"; options...)
