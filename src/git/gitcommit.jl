mutable struct GitCommit <: GitHubType
    sha          :: ?{String}
    url          :: ?{HTTP.URI}
    author       :: ?{Dict}
    commiter     :: ?{Dict}
    message      :: ?{String}
    tree         :: ?{Dict}
    parents      :: ?{Vector}
    verification :: ?{Dict}
end

GitCommit(data::Dict) = json2github(GitCommit, data)
namefield(gitcommit::GitCommit) = gitcommit.sha

@api_default function gitcommit(api::GitHubAPI, repo, commit_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/commits/$(name(commit_obj))"; options...)
    return GitCommit(result)
end

@api_default function create_gitcommit(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/commits"; options...)
    return GitCommit(result)
end
