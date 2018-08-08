mutable struct Reference <: GitHubType
    ref::Union{String, Nothing}
    url::Union{HTTP.URI, Nothing}
    object::Union{Dict, Nothing}
end

Reference(data::Dict) = json2github(Reference, data)

name(ref::Reference) = String(split(ref.ref, "refs/")[2])

@api_default function reference(api::GitHubAPI, repo, ref_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/refs/$(name(ref_obj))"; options...)
    return Reference(result)
end

@api_default function references(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/git/refs"; options...)
    return Reference.((results,)), page_data
end

@api_default function create_reference(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/refs"; options...)
    return Reference(result)
end

@api_default function update_reference(api::GitHubAPI, repo, ref_obj; options...)
    result = gh_patch_json(api, "/repos/$(name(repo))/git/refs/$(name(ref_obj))"; options...)
    return Reference(result)
end

@api_default function delete_reference(api::GitHubAPI, repo, ref_obj; options...)
    return gh_delete(api, "/repos/$(name(repo))/git/refs/$(name(ref_obj))"; options...)
end
