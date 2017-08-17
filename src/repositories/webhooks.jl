################
# Webhook type #
################

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

@api_default function create_webhook(api::GitHubAPI, owner, repo; options...)
    result = gh_post_json(api, "/repos/$(name(owner))/$(name(repo))/hooks"; options...)
    return Webhook(result)
end
