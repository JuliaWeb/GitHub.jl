@ghdef mutable struct Release
    url::Union{Nothing, HTTP.URI}
    html_url::Union{Nothing, HTTP.URI}
    assets_url::Union{Nothing, HTTP.URI}
    upload_url::Union{Nothing, HTTP.URI}
    tarball_url::Union{Nothing, HTTP.URI}
    zipball_url::Union{Nothing, HTTP.URI}
    id::Union{Nothing, Int}
    node_id::Union{Nothing, String}
    tag_name::Union{Nothing, String}
    target_commitish::Union{Nothing, String}
    name::Union{Nothing, String}
    body::Union{Nothing, String}
    draft::Union{Nothing, Bool}
    prerelease::Union{Nothing, Bool}
    created_at::Union{Nothing, String}
    published_at::Union{Nothing, String}
    author::Union{Nothing, Dict{String, Any}}
    assets::Union{Nothing, Array{Any, 1}}
end

namefield(r::Release) = r.id

@api_default function create_release(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/releases"; options...)
    return Release(result)
end

@api_default function releases(api::GitHubAPI, repo; options...)
    result, paged_data = gh_get_paged_json(api, "/repos/$(name(repo))/releases"; options...)
    return map(Release, result), paged_data
end
