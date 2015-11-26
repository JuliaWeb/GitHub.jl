#############
# Repo Type #
#############

type Repo <: GitHubType
    name::Nullable{GitHubString}
    full_name::Nullable{GitHubString}
    description::Nullable{GitHubString}
    language::Nullable{GitHubString}
    default_branch::Nullable{GitHubString}
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
    url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    homepage::Nullable{HttpCommon.URI}
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

repo(repo; options...) = Repo(github_get_json("/repos/$(name(repo))"; options...))

# forks #
#-------#

function forks(repo; options...)
    path = "/repos/$(name(repo))/forks"
    return map(Repo, github_get_json(path; options...))
end

function create_fork(repo; options...)
    path = "/repos/$(name(repo))/forks"
    return Repo(github_post_json(path; options...))
end

# contributors/collaborators #
#----------------------------#

function contributors(repo; options...)
    path = "/repos/$(name(repo))/contributors"
    items = github_get_json(path; options...)
    return [Dict("contributor" => Owner(i), "contributions" => i["contributions"]) for i in items]
end

function collaborators(repo; options...)
    path = "/repos/$(name(repo))/collaborators"
    return map(Owner, github_get_json(path; options...))
end

function iscollaborator(repo, user; options...)
    path = "/repos/$(name(repo))/collaborators/$(name(user))"
    r = github_get(path; handle_error = false, options...)
    r.status == 204 && return true
    r.status == 404 && return false
    handle_response_error(r)  # 404 is not an error in this case
    return false
end

function add_collaborator(repo, user; options...)
    path = "/repos/$(name(repo))/collaborators/$(name(user))"
    return github_put(path; options...)
end

function remove_collaborator(repo, user; options...)
    path = "/repos/$(name(repo))/collaborators/$(name(user))"
    return github_delete(path; options...)
end

# stats #
#-------#

function stats(repo, stat, attempts = 3; options...)
    path = "/repos/$(name(repo))/stats/$(name(stat))"
    local r
    for a in 1:attempts
        r = github_get(path; handle_error = false, options...)
        r.status == 200 && return r
        sleep(2.0)
    end
    return r
end
