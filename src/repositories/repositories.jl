#############
# Repo Type #
#############

mutable struct Repo <: GitHubType
    name              :: ?{String}
    full_name         :: ?{String}
    description       :: ?{String}
    language          :: ?{String}
    default_branch    :: ?{String}
    owner             :: ?{Owner}
    parent            :: ?{Repo}
    source            :: ?{Repo}
    id                :: ?{Int}
    size              :: ?{Int}
    subscribers_count :: ?{Int}
    forks_count       :: ?{Int}
    stargazers_count  :: ?{Int}
    watchers_count    :: ?{Int}
    open_issues_count :: ?{Int}
    url               :: ?{HTTP.URI}
    html_url          :: ?{HTTP.URI}
    homepage          :: ?{HTTP.URI}
    pushed_at         :: ?{Dates.DateTime}
    created_at        :: ?{Dates.DateTime}
    updated_at        :: ?{Dates.DateTime}
    has_issues        :: ?{Bool}
    has_wiki          :: ?{Bool}
    has_downloads     :: ?{Bool}
    has_pages         :: ?{Bool}
    private           :: ?{Bool}
    fork              :: ?{Bool}
    permissions       :: ?{Dict}
end

Repo(data::Dict) = json2github(Repo, data)
Repo(full_name::AbstractString) = Repo(Dict("full_name" => full_name))

name(repo::Repo) = repo.full_name

###############
# API Methods #
###############

# repos #
#-------#

@api_default function repo(api::GitHubAPI, repo_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo_obj))"; options...)
    return Repo(result)
end

@api_default function create_repo(api::GitHubAPI, owner, name::String, params=Dict{String,Any}(); options...)
    params["name"] = name
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
