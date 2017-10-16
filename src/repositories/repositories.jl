#############
# Repo Type #
#############

mutable struct Repo <: GitHubType
    name::Nullable{String}
    full_name::Nullable{String}
    description::Nullable{String}
    language::Nullable{String}
    default_branch::Nullable{String}
    owner::Nullable{Owner}
    parent::Nullable{Repo}
    source::Nullable{Repo}
    id::Nullable{Int}
    size::Nullable{Int}
    subscribers_count::Nullable{Int}
    forks_count::Nullable{Int}
    stargazers_count::Nullable{Int}
    watchers_count::Nullable{Int}
    open_issues_count::Nullable{Int}
    url::Nullable{HTTP.URI}
    html_url::Nullable{HTTP.URI}
    homepage::Nullable{HTTP.URI}
    pushed_at::Nullable{Dates.DateTime}
    created_at::Nullable{Dates.DateTime}
    updated_at::Nullable{Dates.DateTime}
    has_issues::Nullable{Bool}
    has_wiki::Nullable{Bool}
    has_downloads::Nullable{Bool}
    has_pages::Nullable{Bool}
    private::Nullable{Bool}
    fork::Nullable{Bool}
    permissions::Nullable{Dict}
end

Repo(data::Dict) = json2github(Repo, data)
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
