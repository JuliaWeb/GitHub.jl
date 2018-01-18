####################
# PullRequest Type #
####################

mutable struct PullRequest <: GitHubType
    base             :: ?{Branch}
    head             :: ?{Branch}
    number           :: ?{Int}
    id               :: ?{Int}
    comments         :: ?{Int}
    commits          :: ?{Int}
    additions        :: ?{Int}
    deletions        :: ?{Int}
    changed_files    :: ?{Int}
    state            :: ?{String}
    title            :: ?{String}
    body             :: ?{String}
    merge_commit_sha :: ?{String}
    created_at       :: ?{Dates.DateTime}
    updated_at       :: ?{Dates.DateTime}
    closed_at        :: ?{Dates.DateTime}
    merged_at        :: ?{Dates.DateTime}
    url              :: ?{HTTP.URI}
    html_url         :: ?{HTTP.URI}
    assignee         :: ?{Owner}
    user             :: ?{Owner}
    merged_by        :: ?{Owner}
    milestone        :: ?{Dict}
    _links           :: ?{Dict}
    mergeable        :: ?{Bool}
    merged           :: ?{Bool}
    locked           :: ?{Bool}
end

PullRequest(data::Dict) = json2github(PullRequest, data)
PullRequest(number::Real) = PullRequest(Dict("number" => number))

name(pr::PullRequest) = pr.number

###############
# API Methods #
###############

@api_default function pull_requests(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/pulls"; options...)
    return map(PullRequest, results), page_data
end

@api_default function pull_request(api::GitHubAPI, repo, pr; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/pulls/$(name(pr))"; options...)
    return PullRequest(result)
end

@api_default function update_pull_request(api::GitHubAPI, repo, pr; options...)
    result = gh_patch_json(api, "/repos/$(name(repo))/pulls/$(name(pr))"; options...)
    return PullRequest(result)
end

@api_default function close_pull_request(api::GitHubAPI, repo, pr; options...)
    update_pull_request(api, repo, pr; params = Dict(
        :state => "closed"
    ), options...)
end

@api_default function create_pull_request(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/pulls"; options...)
    return PullRequest(result)
end

@api_default function create_comment(api::GitHubAPI, repo, pr::PullRequest, body::AbstractString; options...)
    create_comment(api, repo, pr, :pr; params = Dict(
        :body => body
    ), options...)
end
