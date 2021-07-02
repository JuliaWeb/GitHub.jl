################
# License Type #
################

@ghdef mutable struct License
    key::Union{String, Nothing}
    name::Union{String, Nothing}
    spdx_id::Union{String, Nothing}
    url::Union{HTTP.URI, Nothing}
    html_url::Union{HTTP.URI, Nothing}
    description::Union{String, Nothing}
    permissions::Union{Vector{String}, Nothing}
    conditions::Union{Vector{String}, Nothing}
    limitations::Union{Vector{String}, Nothing}
    body::Union{String, Nothing}
    featured::Union{Bool, Nothing}
end

License(spdx_id::AbstractString) = License(Dict("spdx_id" => spdx_id))

namefield(license::License) = license.spdx_id

###############
# API Methods #
###############

@api_default function licenses(api::GitHubAPI; options...)
    results, page_data = gh_get_paged_json(api, "/licenses"; options...)
    results = [License(result) for result in results]
    return results, page_data
end

@api_default function license(api::GitHubAPI, license_id; options...)
    result = gh_get_json(api, "/licenses/$license_id"; options...)
    return License(result)
end

@api_default function repo_license(api::GitHubAPI, repo_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo_obj))/license"; options...)
    return Content(result)
end
