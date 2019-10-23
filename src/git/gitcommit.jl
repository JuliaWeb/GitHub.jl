@ghdef mutable struct GitCommit
    sha::Union{String, Nothing}
    url::Union{HTTP.URI, Nothing}
    author::Union{Dict, Nothing}
    commiter::Union{Dict, Nothing}
    message::Union{String, Nothing}
    tree::Union{Dict, Nothing}
    parents::Union{Vector, Nothing}
    verification::Union{Dict, Nothing}
end

namefield(gitcommit::GitCommit) = gitcommit.sha

@api_default function gitcommit(api::GitHubAPI, repo, commit_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/commits/$(name(commit_obj))"; options...)
    return GitCommit(result)
end

@api_default function create_gitcommit(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/commits"; options...)
    return GitCommit(result)
end
