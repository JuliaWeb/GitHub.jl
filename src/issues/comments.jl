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

###############
# API Methods #
###############

commentpath(review) = review ? "pulls" : "issues"

function comment(repo, comment_obj, review = false; options...)
    path = "/repos/$(name(repo))/$(commentpath(review))/comments/$(name(comment_obj))"
    return Comment(github_get_json(path; options...))
end

function comments(repo, issue_or_pr, review = false; options...)
    path = "/repos/$(name(repo))/$(commentpath(review))/$(name(issue_or_pr))/comments"
    return map(Comment, github_get_json(path; options...))
end

function create_comment(repo, issue_or_pr, review = false; options...)
    path = "/repos/$(name(repo))/$(commentpath(review))/$(name(issue_or_pr))/comments"
    return Comment(github_post_json(path; options...))
end

function edit_comment(repo, comment, review = false; options...)
    path = "/repos/$(name(repo))/$(commentpath(review))/comments/$(name(comment))"
    return Comment(github_patch_json(path; options...))
end

function delete_comment(repo, comment, review = false; options...)
    path = "/repos/$(name(repo))/$(commentpath(review))/comments/$(name(comment))"
    return github_delete(path; options...)
end
