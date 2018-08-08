################
# Comment Type #
################

mutable struct Comment <: GitHubType
    body::Union{String, Nothing}
    path::Union{String, Nothing}
    diff_hunk::Union{String, Nothing}
    original_commit_id::Union{String, Nothing}
    commit_id::Union{String, Nothing}
    id::Union{Int, Nothing}
    original_position::Union{Int, Nothing}
    position::Union{Int, Nothing}
    line::Union{Int, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    url::Union{HTTP.URI, Nothing}
    html_url::Union{HTTP.URI, Nothing}
    issue_url::Union{HTTP.URI, Nothing}
    pull_request_url::Union{HTTP.URI, Nothing}
    user::Union{Owner, Nothing}
end

Comment(data::Dict) = json2github(Comment, data)
Comment(id::Real) = Comment(Dict("id" => id))

namefield(comment::Comment) = comment.id

kind_err_str(kind) = ("Error building comment request: :$kind is not a valid kind of comment.\n"*
                      "The only valid comment kinds are: :issue, :review, :commit")
###############
# API Methods #
###############

@api_default function comment(api::GitHubAPI, repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        path = "/repos/$(name(repo))/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/repos/$(name(repo))/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_get_json(api, path; options...))
end

@api_default function comments(api::GitHubAPI, repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        path = "/repos/$(name(repo))/issues/$(name(item))/comments"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/$(name(item))/comments"
    elseif kind == :commit
        path = "/repos/$(name(repo))/commits/$(name(item))/comments"
    else
        error(kind_err_str(kind))
    end
    results, page_data = gh_get_paged_json(api, path; options...)
    return map(Comment, results), page_data
end

@api_default function create_comment(api::GitHubAPI, repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        path = "/repos/$(name(repo))/issues/$(name(item))/comments"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/$(name(item))/comments"
    elseif kind == :commit
        path = "/repos/$(name(repo))/commits/$(name(item))/comments"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_post_json(api, path; options...))
end

@api_default function edit_comment(api::GitHubAPI, repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        path = "/repos/$(name(repo))/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/repos/$(name(repo))/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_patch_json(api, path; options...))
end

@api_default function delete_comment(api::GitHubAPI, repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        path = "/repos/$(name(repo))/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/repos/$(name(repo))/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return gh_delete(api, path; options...)
end
