mutable struct Tree <: GitHubType
    sha::Nullable{String}
    url::Nullable{HttpCommon.URI}
    tree::Nullable{Vector}
    truncated::Nullable{Bool}
end

Tree(data::Dict) = json2github(Tree, data)
namefield(tree::Tree) = tree.sha

@api_default function tree(api::GitHubAPI, repo, tree_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/trees/$(name(tree_obj))"; options...)
    return Tree(result)
end

@api_default function create_tree(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/trees"; options...)
    return Tree(result)
end
