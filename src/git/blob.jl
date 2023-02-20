################
# Blob Type #
################

@ghdef mutable struct Blob
    content::Union{String, Nothing}
    encoding::Union{String, Nothing}
    url::Union{URIs.URI, Nothing}
    sha::Union{String, Nothing}
    size::Union{Int, Nothing}
end

Blob(sha::AbstractString) = Blob(Dict("sha" => sha))

namefield(blob::Blob) = blob.sha

function Base.String(blob::Blob)
    @assert blob.encoding == "base64"
    String(base64decode(blob.content))
end

###############
# API Methods #
###############

@api_default function blob(api::GitHubAPI, repo, blob_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/blobs/$(name(blob_obj))"; options...)
    return Blob(result)
end

@api_default function create_blob(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/blobs"; options...)
    return Blob(result)
end

