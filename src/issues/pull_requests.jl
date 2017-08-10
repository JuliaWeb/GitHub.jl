####################
# PullRequest Type #
####################

type PullRequest <: GitHubType
    base::Nullable{Branch}
    head::Nullable{Branch}
    number::Nullable{Int}
    id::Nullable{Int}
    comments::Nullable{Int}
    commits::Nullable{Int}
    additions::Nullable{Int}
    deletions::Nullable{Int}
    changed_files::Nullable{Int}
    state::Nullable{String}
    title::Nullable{String}
    body::Nullable{String}
    merge_commit_sha::Nullable{String}
    created_at::Nullable{Dates.DateTime}
    updated_at::Nullable{Dates.DateTime}
    closed_at::Nullable{Dates.DateTime}
    merged_at::Nullable{Dates.DateTime}
    url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    assignee::Nullable{Owner}
    user::Nullable{Owner}
    merged_by::Nullable{Owner}
    milestone::Nullable{Dict}
    _links::Nullable{Dict}
    mergeable::Nullable{Bool}
    merged::Nullable{Bool}
    locked::Nullable{Bool}
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

@api_default function create_pull_request(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/pulls"; options...)
    return PullRequest(result)
end

@api_default function create_comment(api::GitHubAPI, repo, pr::PullRequest, body::AbstractString; options...)
    create_comment(api, repo, pr, :pr; params = Dict(
        :body => body
    ), options...)
end
