################
# Webhook type #
################

mutable struct Webhook <: GitHubType
    id::Nullable{Int}
    url::Nullable{HTTP.URI}
    test_url::Nullable{HTTP.URI}
    ping_url::Nullable{HTTP.URI}
    name::Nullable{String}
    events::Nullable{Array{String}}
    active::Nullable{Bool}
    config::Nullable{Dict{String, String}}
    updated_at::Nullable{Dates.DateTime}
    created_at::Nullable{Dates.DateTime}
end

Webhook(data::Dict) = json2github(Webhook, data)
Webhook(id::Real) = Webhook(Dict("id" => id))
namefield(hook::Webhook) = hook.id

###############
# API Methods #
###############

@api_default function create_webhook(api::GitHubAPI, owner, repo; options...)
    result = gh_post_json(api, "/repos/$(name(owner))/$(name(repo))/hooks"; options...)
    return Webhook(result)
end
