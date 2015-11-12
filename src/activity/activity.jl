############
# Starring #
############

function stargazers(owner, repo; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/stargazers"
    return map(Owner, github_paged_get(path; options...))
end

function starred(user; options...)
    path = "/users/$(urirepr(user))/starred"
    return map(Repo, github_paged_get(path; options...))
end

function star(owner, repo; options...)
    path = "/user/starred/$(urirepr(owner))/$(urirepr(repo))"
    return github_put(path; options...)
end

function unstar(owner, repo; options...)
    path = "/user/starred/$(urirepr(owner))/$(urirepr(repo))"
    return github_delete(path; options...)
end

############
# Watching #
############

function watchers(owner, repo; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/subscribers"
    return map(Owner, github_paged_get(path; options...))
end

function watched(owner; options...)
    path = "/users/$(urirepr(user))/subscriptions"
    return map(Repo, github_paged_get(path; options...))
end

function watching(owner, repo; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/subscription"
    r = github_get(path; handle_error = false, options...)
    r.status == 200 && return true
    r.status == 404 && return false
    handle_response_error(r)  # 404 is not an error in this case
    return false
end

function watch(owner, repo; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/subscription"
    return github_put(path; options...)
end

function watch(owner, repo; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/subscription"
    return github_delete(path; options...)
end
