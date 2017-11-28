mutable struct Tag <: GitHubType
    tag::Nullable{String}
    sha::Nullable{String}
    url::Nullable{HttpCommon.URI}
    message::Nullable{String}
    tagger::Nullable{Dict}
    object::Nullable{Dict}
    verification::Nullable{Dict}
end

Tag(data::Dict) = json2github(Tag, data)
namefield(tag::Tag) = tag.sha

@api_default function tag(api::GitHubAPI, repo, tag_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/tags/$(name(tag_obj))"; options...)
    return Tag(result)
end

@api_default function create_tag(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/tags"; options...)
    return Tag(result)
end
