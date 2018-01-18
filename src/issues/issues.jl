##############
# Issue type #
##############

mutable struct Issue <: GitHubType
    id           :: ?{Int}
    number       :: ?{Int}
    comments     :: ?{Int}
    title        :: ?{String}
    state        :: ?{String}
    body         :: ?{String}
    user         :: ?{Owner}
    assignee     :: ?{Owner}
    closed_by    :: ?{Owner}
    created_at   :: ?{Dates.DateTime}
    updated_at   :: ?{Dates.DateTime}
    closed_at    :: ?{Dates.DateTime}
    labels       :: ?{Vector{Dict}}
    milestone    :: ?{Dict}
    pull_request :: ?{PullRequest}
    url          :: ?{HTTP.URI}
    html_url     :: ?{HTTP.URI}
    labels_url   :: ?{HTTP.URI}
    comments_url :: ?{HTTP.URI}
    events_url   :: ?{HTTP.URI}
    locked       :: ?{Bool}
end

Issue(data::Dict) = json2github(Issue, data)
Issue(number::Real) = Issue(Dict("number" => number))

name(issue::Issue) = issue.number

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
