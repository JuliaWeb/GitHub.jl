##############
# Issue type #
##############

@ghdef mutable struct Issue
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
    url::Union{URIs.URI, Nothing}
    html_url::Union{URIs.URI, Nothing}
    labels_url::Union{URIs.URI, Nothing}
    comments_url::Union{URIs.URI, Nothing}
    events_url::Union{URIs.URI, Nothing}
    locked::Union{Bool, Nothing}
end

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

# labels #
#--------#

@api_default function labels(api::GitHubAPI, repo, issue; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/issues/$(name(issue))/labels"; options...)
    return Label.(result)
end

@api_default function add_labels(api::GitHubAPI, repo, issue, labels; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/issues/$(name(issue))/labels";
                          params=Dict("labels" => name.(labels)), options...)
    return Label.(result)
end

@api_default function set_labels(api::GitHubAPI, repo, issue, labels; options...)
    result = gh_put_json(api, "/repos/$(name(repo))/issues/$(name(issue))/labels";
                         params=Dict("labels" => name.(labels)), options...)
    return Label.(result)
end

@api_default function remove_all_labels(api::GitHubAPI, repo, issue; options...)
    return gh_delete(api, "/repos/$(name(repo))/issues/$(name(issue))/labels"; options...)
end

@api_default function remove_label(api::GitHubAPI, repo, issue, label; options...)
    return gh_delete(api, "/repos/$(name(repo))/issues/$(name(issue))/labels/$(name(label))"; options...)
end
