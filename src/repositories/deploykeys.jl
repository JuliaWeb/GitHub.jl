mutable struct DeployKey <: GitHubType
    id::Union{Int, Nothing}
    key::Union{String, Nothing}
    url::Union{HTTP.URI, Nothing}
    title::Union{String, Nothing}
    verified::Union{Bool, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    read_only::Union{Bool, Nothing}
end

DeployKey(data::Dict) = json2github(DeployKey, data)

namefield(key::DeployKey) = key.id

@api_default function deploykey(api::GitHubAPI, repo, deploykey_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/keys/$(name(deploykey_obj))"; options...)
    return DeployKey(result)
end

@api_default function deploykeys(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/keys"; options...)
    return map(DeployKey, results), page_data
end

@api_default function create_deploykey(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/keys"; options...)
    return DeployKey(result)
end

@api_default function delete_deploykey(api::GitHubAPI, repo, item; options...)
    return gh_delete(api, "/repos/$(name(repo))/keys/$(name(item))"; options...)
end