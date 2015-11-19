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

urifield(status::Status) = status.id

###############
# API Methods #
###############

function create_status(owner, repo, sha; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/statuses/$(urirepr(sha))"
    return Status(github_post_json(path; options...))
end

function statuses(owner, repo, ref; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/commits/$(urirepr(ref))/statuses"
    return map(Status, github_paged_get(path; options...))
end
