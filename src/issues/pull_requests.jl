####################
# PullRequest Type #
####################

@ghdef mutable struct PullRequest
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

PullRequest(number::Real) = PullRequest(Dict("number" => number))
namefield(pr::PullRequest) = pr.number

@ghdef mutable struct PullRequestFile
    raw_url::Union{String, Nothing}
    status::Union{String, Nothing}
    patch::Union{String, Nothing}
    changes::Union{Int, Nothing}
    sha::Union{String, Nothing}
    filename::Union{String, Nothing}
    additions::Union{Int, Nothing}
    deletions::Union{Int, Nothing}
    blob_url::Union{String, Nothing}
    contents_url::Union{String, Nothing}
end

PullRequestFile(fname::String) = PullRequestFile(Dict("filename" => fname))
namefield(prf::PullRequestFile) = prf.filename

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

@api_default function pull_request_files(api::GitHubAPI, repo, pr; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/pulls/$(name(pr))/files"; options...)
    return [PullRequestFile(f) for f in result]
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

@api_default function merge_pull_request(api::GitHubAPI, repo, pr; options...)
    gh_put_json(api, "/repos/$(name(repo))/pulls/$(name(pr))/merge"; options...)
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
