################
# Webhook type #
################

mutable struct Webhook <: GitHubType
    id         :: ?{Int}
    url        :: ?{HTTP.URI}
    test_url   :: ?{HTTP.URI}
    ping_url   :: ?{HTTP.URI}
    name       :: ?{String}
    events     :: ?{Array{String}}
    active     :: ?{Bool}
    config     :: ?{Dict{String, String}}
    updated_at :: ?{Dates.DateTime}
    created_at :: ?{Dates.DateTime}
end

Webhook(data::Dict) = json2github(Webhook, data)
Webhook(id::Real) = Webhook(Dict("id" => id))
name(hook::Webhook) = hook.id

###############
# API Methods #
###############

@api_default function create_webhook(api::GitHubAPI, owner, repo; options...)
    result = gh_post_json(api, "/repos/$(name(owner))/$(name(repo))/hooks"; options...)
    return Webhook(result)
end
