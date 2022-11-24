###################
# Comparison Type #
###################

@ghdef mutable struct Comparison
    url::Union{URIs.URI, Nothing}
    html_url::Union{URIs.URI, Nothing}
    permalink_url::Union{URIs.URI, Nothing}
    diff_url::Union{URIs.URI, Nothing}
    patch_url::Union{URIs.URI, Nothing}
    base_commit::Union{Commit, Nothing}
    merge_base_commit::Union{Commit, Nothing}
    status::Union{String, Nothing}
    ahead_by::Union{Int, Nothing}
    behind_by::Union{Int, Nothing}
    total_commits::Union{Int, Nothing}
    commits::Union{Vector{Commit}, Nothing}
    files::Union{Vector{Content}, Nothing}
end

###############
# API Methods #
###############

@api_default function compare(api::GitHubAPI, repo, base, head; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/compare/$(name(base))...$(name(head))"; options...)
    return Comparison(result)
end
