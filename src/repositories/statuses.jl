###############
# Status type #
###############

type Status <: GitHubType
    id::Nullable{Int}
    state::Nullable{GitHubString}
    description::Nullable{GitHubString}
    context::Nullable{GitHubString}
    url::Nullable{HttpCommon.URI}
    target_url::Nullable{HttpCommon.URI}
    created_at::Nullable{Dates.DateTime}
    updated_at::Nullable{Dates.DateTime}
    creator::Nullable{Owner}
end

Status(data::Dict) = json2github(Status, data)
Status(id::Real) = Status(Dict("id" => id))

namefield(status::Status) = status.id

###############
# API Methods #
###############

function create_status(owner, repo, sha; options...)
    path = "/repos/$(name(owner))/$(name(repo))/statuses/$(name(sha))"
    return Status(github_post_json(path; options...))
end

function statuses(owner, repo, ref; options...)
    path = "/repos/$(name(owner))/$(name(repo))/commits/$(name(ref))/statuses"
    return map(Status, github_paged_get(path; options...))
end
