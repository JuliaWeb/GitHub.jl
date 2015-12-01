################
# Comment Type #
################

type Comment <: GitHubType
    body::Nullable{GitHubString}
    path::Nullable{GitHubString}
    diff_hunk::Nullable{GitHubString}
    original_commit_id::Nullable{GitHubString}
    commit_id::Nullable{GitHubString}
    id::Nullable{Int}
    original_position::Nullable{Int}
    position::Nullable{Int}
    line::Nullable{Int}
    created_at::Nullable{Dates.DateTime}
    updated_at::Nullable{Dates.DateTime}
    url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    issue_url::Nullable{HttpCommon.URI}
    pull_request_url::Nullable{HttpCommon.URI}
    user::Nullable{Owner}
end

Comment(data::Dict) = json2github(Comment, data)
Comment(id::Real) = Comment(Dict("id" => id))

namefield(comment::Comment) = comment.id

kind_err_str(kind) = ("Error building comment request: :$kind is not a valid kind of comment.\n"*
                      "The only valid comment kinds are: :issue, :review, :commit")
###############
# API Methods #
###############

function comment(repo, item, kind = :issue; options...)
    if kind == :issue
        path = "/repos/$(name(repo))/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/repos/$(name(repo))/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_get_json(path; options...))
end

function comments(repo, item, kind = :issue; options...)
    if kind == :issue
        path = "/repos/$(name(repo))/issues/$(name(item))/comments"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/$(name(item))/comments"
    elseif kind == :commit
        path = "/repos/$(name(repo))/commits/$(name(item))/comments"
    else
        error(kind_err_str(kind))
    end
    results, page_data = gh_get_paged_json(path; options...)
    return map(Comment, results), page_data
end

function create_comment(repo, item, kind = :issue; options...)
    if kind == :issue
        path = "/repos/$(name(repo))/issues/$(name(item))/comments"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/$(name(item))/comments"
    elseif kind == :commit
        path = "/repos/$(name(repo))/commits/$(name(item))/comments"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_post_json(path; options...))
end

function edit_comment(repo, item, kind = :issue; options...)
    if kind == :issue
        path = "/repos/$(name(repo))/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/repos/$(name(repo))/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_patch_json(path; options...))
end

function delete_comment(repo, item, isreview = false; options...)
    if kind == :issue
        path = "/repos/$(name(repo))/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/repos/$(name(repo))/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/repos/$(name(repo))/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return gh_delete(path; options...)
end
