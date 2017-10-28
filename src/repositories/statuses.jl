###############
# Status type #
###############

mutable struct Status <: GitHubType
    id::Nullable{Int}
    total_count::Nullable{Int}
    state::Nullable{String}
    description::Nullable{String}
    context::Nullable{String}
    sha::Nullable{String}
    url::Nullable{HTTP.URI}
    target_url::Nullable{HTTP.URI}
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

@api_default function create_status(api::GitHubAPI, repo, sha; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/statuses/$(name(sha))"; options...)
    return Status(result)
end

@api_default function statuses(api::GitHubAPI, repo, ref; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/commits/$(name(ref))/statuses"; options...)
    return map(Status, results), page_data
end

@api_default function status(api::GitHubAPI, repo, ref; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/commits/$(name(ref))/status"; options...)
    return Status(result)
end
