##############
# Issue type #
##############

type Issue <: GitHubType
    id::Nullable{Int}
    number::Nullable{Int}
    comments::Nullable{Int}
    title::Nullable{String}
    state::Nullable{String}
    body::Nullable{String}
    user::Nullable{Owner}
    assignee::Nullable{Owner}
    closed_by::Nullable{Owner}
    created_at::Nullable{Dates.DateTime}
    updated_at::Nullable{Dates.DateTime}
    closed_at::Nullable{Dates.DateTime}
    labels::Nullable{Vector{Dict}}
    milestone::Nullable{Dict}
    pull_request::Nullable{PullRequest}
    url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    labels_url::Nullable{HttpCommon.URI}
    comments_url::Nullable{HttpCommon.URI}
    events_url::Nullable{HttpCommon.URI}
    locked::Nullable{Bool}
end

Issue(data::Dict) = json2github(Issue, data)
Issue(number::Real) = Issue(Dict("number" => number))

namefield(issue::Issue) = issue.number

###############
# API Methods #
###############

function issue(repo, issue_obj; options...)
    result = gh_get_json("/repos/$(name(repo))/issues/$(name(issue_obj))"; options...)
    return Issue(result)
end

function issues(repo; options...)
    results, page_data = gh_get_paged_json("/repos/$(name(repo))/issues"; options...)
    return map(Issue, results), page_data
end

function create_issue(repo; options...)
    result = gh_post_json("/repos/$(name(repo))/issues"; options...)
    return Issue(result)
end

function edit_issue(repo, issue; options...)
    result = gh_patch_json("/repos/$(name(repo))/issues/$(name(issue))"; options...)
    return Issue(result)
end
