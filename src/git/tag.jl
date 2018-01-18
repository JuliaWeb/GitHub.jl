mutable struct Tag <: GitHubType
    tag          :: ?{String}
    sha          :: ?{String}
    url          :: ?{HTTP.URI}
    message      :: ?{String}
    tagger       :: ?{Dict}
    object       :: ?{Dict}
    verification :: ?{Dict}
end

Tag(data::Dict) = json2github(Tag, data)
name(tag::Tag) = tag.sha

@api_default function tag(api::GitHubAPI, repo, tag_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/git/tags/$(name(tag_obj))"; options...)
    return Tag(result)
end

@api_default function create_tag(api::GitHubAPI, repo; options...)
    result = gh_post_json(api, "/repos/$(name(repo))/git/tags"; options...)
    return Tag(result)
end
