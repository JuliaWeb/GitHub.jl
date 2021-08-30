@ghdef mutable struct Label
    name::Union{String, Nothing}
    default::Union{Bool, Nothing}
    id::Union{Int, Nothing}
    color::Union{String, Nothing}
    node_id::Union{String, Nothing}
    url::Union{String, Nothing}
    description::Union{String, Nothing}
end

namefield(label::Label) = label.name

Label(name::AbstractString) = Label(Dict("name" => name))

@api_default function labels(api::GitHubAPI, repo, issue; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/issues/$(name(issue))/labels"; options...)
    return Label.(result)
end

@api_default function add_labels(api::GitHubAPI, repo, issue, labels; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/issues/$(name(issue))/labels";
                          params=Dict("labels" => name.(labels)), options...)
    return Label.(result)
end

@api_default function set_labels(api::GitHubAPI, repo, issue, labels; options...)
    result = gh_put_json(api, "/repos/$(name(repo))/issues/$(name(issue))/labels";
                         params=Dict("labels" => name.(labels)), options...)
    return Label.(result)
end

@api_default function remove_all_labels(api::GitHubAPI, repo, issue; options...)
    return gh_delete(api, "/repos/$(name(repo))/issues/$(name(issue))/labels"; options...)
end

@api_default function remove_label(api::GitHubAPI, repo, issue, label; options...)
    return gh_delete(api, "/repos/$(name(repo))/issues/$(name(issue))/labels/$(name(label))"; options...)
end
