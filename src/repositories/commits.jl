###############
# Commit Type #
###############

type Commit <: GitHubType
    sha::Nullable{GitHubString}
    message::Nullable{GitHubString}
    author::Nullable{Owner}
    committer::Nullable{Owner}
    commit::Nullable{Commit}
    url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    comments_url::Nullable{HttpCommon.URI}
    parents::Nullable{Vector{Commit}}
    stats::Nullable{Dict}
    files::Nullable{Vector{Content}}
    comment_count::Nullable{Int}
end

Commit(data::Dict) = json2github(Commit, data)

urifield(commit::Commit) = commit.sha

###############
# API Methods #
###############

function commits(owner, repo; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/commits"
    return map(Commit, github_paged_get(path; options...))
end

function commit(owner, repo, sha; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/commits/$(urirepr(sha))"
    return Commit(github_get_json(path; options...))
end
