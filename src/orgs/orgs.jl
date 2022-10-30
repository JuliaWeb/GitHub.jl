##############
# Organization Type #
##############

@ghdef mutable struct Invite
    # id::Union{Int, Nothing}
    # login::Union{String, Nothing}
    # node_id::Union{String, Nothing}
    # email::Union{String, Nothing}
    # role::Union{String, Nothing}
    # created_at::Union{String, Nothing}
    # inviter::Union{Any, Nothing}
    # team_count::Union{Int, Nothing}
    invitation_teams_url::Union{String, Nothing}
end

@api_default function invitations(api::GitHubAPI, org::String, params=Dict{String,Any}(); options...)
    results, page_data = gh_post_json(api, "/orgs/$(org)/invitations"; params=params, options...)
    return map(Invite, results), page_data
end