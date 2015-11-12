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

urirepr(comment::Comment) = get(comment.id)
