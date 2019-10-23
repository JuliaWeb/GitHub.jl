#############
# Repo Type #
#############

@ghdef mutable struct Repo
    name::Union{String, Nothing}
    full_name::Union{String, Nothing}
    description::Union{String, Nothing}
    language::Union{String, Nothing}
    default_branch::Union{String, Nothing}
    owner::Union{Owner, Nothing}
    parent::Union{Repo, Nothing}
    source::Union{Repo, Nothing}
    id::Union{Int, Nothing}
    size::Union{Int, Nothing}
    subscribers_count::Union{Int, Nothing}
    forks_count::Union{Int, Nothing}
    stargazers_count::Union{Int, Nothing}
    watchers_count::Union{Int, Nothing}
    open_issues_count::Union{Int, Nothing}
    url::Union{HTTP.URI, Nothing}
    html_url::Union{HTTP.URI, Nothing}
    homepage::Union{HTTP.URI, Nothing}
    pushed_at::Union{Dates.DateTime, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    has_issues::Union{Bool, Nothing}
    has_wiki::Union{Bool, Nothing}
    has_downloads::Union{Bool, Nothing}
    has_pages::Union{Bool, Nothing}
    private::Union{Bool, Nothing}
    fork::Union{Bool, Nothing}
    permissions::Union{Dict, Nothing}
end

Repo(full_name::AbstractString) = Repo(Dict("full_name" => full_name))

namefield(repo::Repo) = repo.full_name

###############
# API Methods #
###############

# repos #
#-------#

@api_default function repo(api::GitHubAPI, repo_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo_obj))"; options...)
    return Repo(result)
end

@api_default function create_repo(api::GitHubAPI, owner, repo_name::String, params=Dict{String,Any}(); options...)
    params["name"] = repo_name
    if isorg(owner)
        result = gh_post_json(api, "/orgs/$(name(owner))/repos"; params=params, options...)
    else
        result = gh_post_json(api, "/user/repos"; params=params, options...)
    end
    return Repo(result)
end

# forks #
#-------#

@api_default function forks(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/forks"; options...)
    return map(Repo, results), page_data
end

@api_default function create_fork(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/forks"; options...)
    return Repo(result)
end

# contributors/collaborators #
#----------------------------#

@api_default function contributors(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/contributors"; options...)
    results = [Dict("contributor" => Owner(i), "contributions" => i["contributions"]) for i in results]
    return results, page_data
end

@api_default function collaborators(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_json(api, "/repos/$(name(repo))/collaborators"; options...)
    return map(Owner, results), page_data
end

@api_default function iscollaborator(api::GitHubAPI, repo, user; options...)
    path = "/repos/$(name(repo))/collaborators/$(name(user))"
    r = gh_get(api, path; handle_error = false, options...)
    r.status == 204 && return true
    r.status == 404 && return false
    handle_response_error(r)  # 404 is not an error in this case
    return false
end

@api_default function add_collaborator(api::GitHubAPI, repo, user; options...)
    path = "/repos/$(name(repo))/collaborators/$(name(user))"
    return gh_put(api, path; options...)
end

@api_default function remove_collaborator(api::GitHubAPI, repo, user; options...)
    path = "/repos/$(name(repo))/collaborators/$(name(user))"
    return gh_delete(api, path; options...)
end

# stats #
#-------#

@api_default function stats(api::GitHubAPI, repo, stat, attempts = 3; options...)
    path = "/repos/$(name(repo))/stats/$(name(stat))"
    local r
    for a in 1:attempts
        r = gh_get(api, path; handle_error = false, options...)
        r.status == 200 && return r
        sleep(2.0)
    end
    return r
end
