############
# Starring #
############

@api_default function stargazers(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/stargazers"; options...)
    return map(Owner, results), page_data
end

@api_default function starred(api::GitHubAPI, user; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(user))/starred"; options...)
    return map(Repo, results), page_data
end

@api_default star(api::GitHubAPI, repo; options...) = gh_put(api, "/user/starred/$(name(repo))"; options...)

@api_default unstar(api::GitHubAPI, repo; options...) = gh_delete(api, "/user/starred/$(name(repo))"; options...)

############
# Watching #
############

@api_default function watchers(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/subscribers"; options...)
    return map(Owner, results), page_data
end

@api_default function watched(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(owner))/subscriptions"; options...)
    return map(Repo, results), page_data
end

@api_default watch(api::GitHubAPI, repo; options...) = gh_put(api, "/repos/$(name(repo))/subscription"; options...)

@api_default unwatch(api::GitHubAPI, repo; options...) = gh_delete(api, "/repos/$(name(repo))/subscription"; options...)
