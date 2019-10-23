################
# Webhook type #
################

@ghdef mutable struct Webhook
    id::Union{Int, Nothing}
    url::Union{HTTP.URI, Nothing}
    test_url::Union{HTTP.URI, Nothing}
    ping_url::Union{HTTP.URI, Nothing}
    name::Union{String, Nothing}
    events::Union{Array{String}, Nothing}
    active::Union{Bool, Nothing}
    config::Union{Dict{String, String}, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
end

Webhook(id::Real) = Webhook(Dict("id" => id))
namefield(hook::Webhook) = hook.id

###############
# API Methods #
###############

@api_default function create_webhook(api::GitHubAPI, owner, repo; options...)
    result = gh_post_json(api, "/repos/$(name(owner))/$(name(repo))/hooks"; options...)
    return Webhook(result)
end
