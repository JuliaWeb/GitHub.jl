mutable struct GitCommit <: GitHubType
    sha::Nullable{String}
    url::Nullable{HTTP.URI}
    author::Nullable{Dict}
    commiter::Nullable{Dict}
    message::Nullable{String}
    tree::Nullable{Dict}
    parents::Nullable{Vector}
    verification::Nullable{Dict}
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
