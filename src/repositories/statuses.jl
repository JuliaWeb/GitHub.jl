###############
# Status type #
###############

mutable struct Status <: GitHubType
    id          :: ?{Int}
    total_count :: ?{Int}
    state       :: ?{String}
    description :: ?{String}
    context     :: ?{String}
    sha         :: ?{String}
    url         :: ?{HTTP.URI}
    target_url  :: ?{HTTP.URI}
    created_at  :: ?{Dates.DateTime}
    updated_at  :: ?{Dates.DateTime}
    creator     :: ?{Owner}
    repository  :: ?{Repo}
    statuses    :: ?{Vector{Status}}
end

Status(data::Dict) = json2github(Status, data)
Status(id::Real) = Status(Dict("id" => id))

name(status::Status) = status.id

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
