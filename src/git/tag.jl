@ghdef mutable struct Tag
    tag::Union{String, Nothing}
    sha::Union{String, Nothing}
    url::Union{URIs.URI, Nothing}
    message::Union{String, Nothing}
    tagger::Union{Dict, Nothing}
    object::Union{Dict, Nothing}
    verification::Union{Dict, Nothing}
end

namefield(tag::Tag) = tag.sha

@api_default function tag(api::GitHubAPI, repo, tag_ref; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/refs/tags/$(name(tag_ref))"; options...)
    if result["object"]["type"] == "tag"
        # lightweight tag pointing to an annotated tag
        result = gh_get_json(api, "/repos/$(name(repo))/git/tags/$(result["object"]["sha"])"; options...)
    end
    return Tag(result)
end

@api_default function tags(api::GitHubAPI, repo; options...)
    result, paged_data = gh_get_paged_json(api, "/repos/$(name(repo))/git/refs/tags"; options...)
    result = map(result) do entry
        if entry["object"]["type"] == "tag"
            # lightweight tag pointing to an annotated tag
            gh_get_json(api, "/repos/$(name(repo))/git/tags/$(entry["object"]["sha"])"; options...)
        else
            entry
        end
    end
    return map(Tag, result), paged_data
end

@api_default function create_tag(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/tags"; options...)
    return Tag(result)
end
