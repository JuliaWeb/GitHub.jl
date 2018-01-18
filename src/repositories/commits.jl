###############
# Commit Type #
###############

mutable struct Commit <: GitHubType
    sha           :: ?{String}
    message       :: ?{String}
    author        :: ?{Owner}
    committer     :: ?{Owner}
    commit        :: ?{Commit}
    url           :: ?{HTTP.URI}
    html_url      :: ?{HTTP.URI}
    comments_url  :: ?{HTTP.URI}
    parents       :: ?{Vector{Commit}}
    stats         :: ?{Dict}
    files         :: ?{Vector{Content}}
    comment_count :: ?{Int}
end

Commit(data::Dict) = json2github(Commit, data)
Commit(sha::AbstractString) = Commit(Dict("sha" => sha))

name(commit::Commit) = commit.sha

###############
# API Methods #
###############

@api_default function commits(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/commits"; options...)
    return map(Commit, results), page_data
end

@api_default function commit(api::GitHubAPI, repo, sha; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/commits/$(name(sha))"; options...)
    return Commit(result)
end
