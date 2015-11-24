############
# Starring #
############

function stargazers(repo; options...)
    path = "/repos/$(name(repo))/stargazers"
    return map(Owner, github_paged_get(path; options...))
end

function starred(user; options...)
    path = "/users/$(name(user))/starred"
    return map(Repo, github_paged_get(path; options...))
end

function star(repo; options...)
    path = "/user/starred/$(name(repo))"
    return github_put(path; options...)
end

function unstar(repo; options...)
    path = "/user/starred/$(name(repo))"
    return github_delete(path; options...)
end

############
# Watching #
############

function watchers(repo; options...)
    path = "/repos/$(name(repo))/subscribers"
    return map(Owner, github_paged_get(path; options...))
end

function watched(owner; options...)
    path = "/users/$(name(owner))/subscriptions"
    return map(Repo, github_paged_get(path; options...))
end

function watch(repo; options...)
    path = "/repos/$(name(repo))/subscription"
    return github_put(path; options...)
end

function watch(repo; options...)
    path = "/repos/$(name(repo))/subscription"
    return github_delete(path; options...)
end
