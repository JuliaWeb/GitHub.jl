###############
# Status type #
###############

type Status <: GitHubType
    id::Nullable{Int}
    total_count::Nullable{Int}
    state::Nullable{String}
    description::Nullable{String}
    context::Nullable{String}
    sha::Nullable{String}
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

type Webhook <: GitHubType
    id::Nullable{Int}
    url::Nullable{HttpCommon.URI}
    test_url::Nullable{HttpCommon.URI}
    ping_url::Nullable{HttpCommon.URI}
    name::Nullable{GitHubString}
    events::Nullable{Array{GitHubString}}
    active::Nullable{Bool}
    config::Nullable{Dict{GitHubString, GitHubString}}
    updated_at::Nullable{Dates.DateTime}
    created_at::Nullable{Dates.DateTime}
end

Webhook(data::Dict) = json2github(Webhook, data)
Webhook(id::Real) = Webhook(Dict("id" => id))
namefield(hook::Webhook) = hook.id

###############
# API Methods #
###############

function create_webhook(owner, repo; options...)
    result = gh_post_json("/repos/$(name(owner))/$(name(repo))/hooks"; options...)
    return Webhook(result)
end

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
