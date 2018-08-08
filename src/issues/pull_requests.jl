####################
# PullRequest Type #
####################

mutable struct PullRequest <: GitHubType
    base::Union{Branch, Nothing}
    head::Union{Branch, Nothing}
    number::Union{Int, Nothing}
    id::Union{Int, Nothing}
    comments::Union{Int, Nothing}
    commits::Union{Int, Nothing}
    additions::Union{Int, Nothing}
    deletions::Union{Int, Nothing}
    changed_files::Union{Int, Nothing}
    state::Union{String, Nothing}
    title::Union{String, Nothing}
    body::Union{String, Nothing}
    merge_commit_sha::Union{String, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    closed_at::Union{Dates.DateTime, Nothing}
    merged_at::Union{Dates.DateTime, Nothing}
    url::Union{HTTP.URI, Nothing}
    html_url::Union{HTTP.URI, Nothing}
    assignee::Union{Owner, Nothing}
    user::Union{Owner, Nothing}
    merged_by::Union{Owner, Nothing}
    milestone::Union{Dict, Nothing}
    _links::Union{Dict, Nothing}
    mergeable::Union{Bool, Nothing}
    merged::Union{Bool, Nothing}
    locked::Union{Bool, Nothing}
end

PullRequest(data::Dict) = json2github(PullRequest, data)
PullRequest(number::Real) = PullRequest(Dict("number" => number))

namefield(pr::PullRequest) = pr.number

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
