##############
# Issue type #
##############

mutable struct Issue <: GitHubType
    id::Union{Int, Nothing}
    number::Union{Int, Nothing}
    comments::Union{Int, Nothing}
    title::Union{String, Nothing}
    state::Union{String, Nothing}
    body::Union{String, Nothing}
    user::Union{Owner, Nothing}
    assignee::Union{Owner, Nothing}
    closed_by::Union{Owner, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    closed_at::Union{Dates.DateTime, Nothing}
    labels::Union{Vector{Dict}, Nothing}
    milestone::Union{Dict, Nothing}
    pull_request::Union{PullRequest, Nothing}
    url::Union{HTTP.URI, Nothing}
    html_url::Union{HTTP.URI, Nothing}
    labels_url::Union{HTTP.URI, Nothing}
    comments_url::Union{HTTP.URI, Nothing}
    events_url::Union{HTTP.URI, Nothing}
    locked::Union{Bool, Nothing}
end

Issue(data::Dict) = json2github(Issue, data)
Issue(number::Real) = Issue(Dict("number" => number))

namefield(issue::Issue) = issue.number

###############
# API Methods #
###############

@api_default function issue(api::GitHubAPI, repo, issue_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/issues/$(name(issue_obj))"; options...)
    return Issue(result)
end

@api_default function issues(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/issues"; options...)
    return map(Issue, results), page_data
end

@api_default function create_issue(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/issues"; options...)
    return Issue(result)
end

@api_default function edit_issue(api::GitHubAPI, repo, issue; options...)
    result = gh_patch_json(api, "/repos/$(name(repo))/issues/$(name(issue))"; options...)
    return Issue(result)
end
