###############
# Status type #
###############

@ghdef mutable struct Status
    id::Union{Int, Nothing}
    total_count::Union{Int, Nothing}
    state::Union{String, Nothing}
    description::Union{String, Nothing}
    context::Union{String, Nothing}
    sha::Union{String, Nothing}
    url::Union{HTTP.URI, Nothing}
    target_url::Union{HTTP.URI, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    creator::Union{Owner, Nothing}
    repository::Union{Repo, Nothing}
    statuses::Union{Vector{Status}, Nothing}
end

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
