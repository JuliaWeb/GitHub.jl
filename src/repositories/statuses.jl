###############
# Status type #
###############

type Status <: GitHubType
    id::Nullable{Int}
    total_count::Nullable{Int}
    state::Nullable{GitHubString}
    description::Nullable{GitHubString}
    context::Nullable{GitHubString}
    sha::Nullable{GitHubString}
    url::Nullable{HttpCommon.URI}
    target_url::Nullable{HttpCommon.URI}
    created_at::Nullable{Dates.DateTime}
    updated_at::Nullable{Dates.DateTime}
    creator::Nullable{Owner}
    repository::Nullable{Repo}
    statuses::Nullable{Vector{Status}}
end

Status(data::Dict) = json2github(Status, data)
Status(id::Real) = Status(Dict("id" => id))

namefield(status::Status) = status.id

###############
# API Methods #
###############

function create_status(repo, sha; options...)
    result = gh_post_json("/repos/$(name(repo))/statuses/$(name(sha))"; options...)
    return Status(result)
end

function statuses(repo, ref; options...)
    results, page_data = gh_get_paged_json("/repos/$(name(repo))/commits/$(name(ref))/statuses"; options...)
    return map(Status, results), page_data
end

function status(repo, ref; options...)
    result = gh_get_json("/repos/$(name(repo))/commits/$(name(ref))/status"; options...)
    return Status(result)
end
