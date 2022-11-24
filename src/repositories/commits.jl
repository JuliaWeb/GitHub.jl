###############
# Commit Type #
###############

@ghdef mutable struct Commit
    sha::Union{String, Nothing}
    message::Union{String, Nothing}
    author::Union{Owner, Nothing}
    committer::Union{Owner, Nothing}
    commit::Union{Commit, Nothing}
    url::Union{URIs.URI, Nothing}
    html_url::Union{URIs.URI, Nothing}
    comments_url::Union{URIs.URI, Nothing}
    parents::Union{Vector{Commit}, Nothing}
    stats::Union{Dict, Nothing}
    files::Union{Vector{Content}, Nothing}
    comment_count::Union{Int, Nothing}
end

Commit(sha::AbstractString) = Commit(Dict("sha" => sha))

namefield(commit::Commit) = commit.sha

###############
# API Methods #
###############

# repo #
#------#

@api_default function commits(api::GitHubAPI, repo::Union{Repo,String}; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/commits"; options...)
    return map(Commit, results), page_data
end

@api_default function commit(api::GitHubAPI, repo, sha::Union{Commit,String}; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/commits/$(name(sha))"; options...)
    return Commit(result)
end

# pull request #
#--------------#

@api_default function commits(api::GitHubAPI, pr; options...)
    repo = pr.base.repo
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/pulls/$(name(pr))/commits"; options...)
    return map(Commit, results), page_data
end

@api_default function commits(api::GitHubAPI, repo, pr; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/pulls/$(name(pr))/commits"; options...)
    return map(Commit, results), page_data
end