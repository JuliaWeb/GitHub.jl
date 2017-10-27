mutable struct Blob <: GitHubType
    content::Nullable{String}
    encoding::Nullable{String}
    url::Nullable{HttpCommon.URI}
    sha::Nullable{String}
    size::Nullable{Int}
end

Blob(data::Dict) = json2github(Blob, data)
Blob(sha::AbstractString) = Blob(Dict("sha" => sha))

namefield(blob::Blob) = blob.sha

@api_default function blob(api::GitHubAPI, repo, blob_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/blobs/$(name(blob_obj))"; options...)
    return Blob(result)
end

@api_default function create_blob(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/blobs"; options...)
    return Blob(result)
end

