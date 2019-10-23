@ghdef mutable struct Tag
    tag::Union{String, Nothing}
    sha::Union{String, Nothing}
    url::Union{HTTP.URI, Nothing}
    message::Union{String, Nothing}
    tagger::Union{Dict, Nothing}
    object::Union{Dict, Nothing}
    verification::Union{Dict, Nothing}
end

namefield(tag::Tag) = tag.sha

@api_default function tag(api::GitHubAPI, repo, tag_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/refs/tags/$(name(tag_obj))"; options...)
    return Tag(result)
end

@api_default function tags(api::GitHubAPI, repo; options...)
    result, paged_data = gh_get_paged_json(api, "/repos/$(name(repo))/git/refs/tags"; options...)
    return map(Tag, result), paged_data
end

@api_default function create_tag(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/tags"; options...)
    return Tag(result)
end
