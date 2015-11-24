##############
# Issue type #
##############

type Issue <: GitHubType
    id::Nullable{Int}
    number::Nullable{Int}
    comments::Nullable{Int}
    title::Nullable{GitHubString}
    state::Nullable{GitHubString}
    body::Nullable{GitHubString}
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

function issue(owner, repo, issue; options...)
    path = "/repos/$(name(owner))/$(name(repo))/issues/$(name(issue))"
    return Issue(github_get_json(path; options...))
end

function issues(owner, repo; options...)
    path = "/repos/$(name(owner))/$(name(repo))/issues"
    return map(Issues, github_paged_get(path; options...))
end

function create_issue(owner, repo; options...)
    path = "/repos/$(name(owner))/$(name(repo))/issues"
    return Issue(github_post_json(path; options...))
end

function edit_issue(owner, repo, issue; options...)
    path = "/repos/$(name(owner))/$(name(repo))/issues/$(name(issue))"
    return Issue(github_patch_json(path; options...))
end

function issue_comments(owner, repo, issue; options...)
    path = "/repos/$(name(owner))/$(name(repo))/issues/$(name(issue))/comments"
    return map(Comment, github_paged_get(path; options...))
end
