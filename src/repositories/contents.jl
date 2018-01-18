################
# Content Type #
################

mutable struct Content <: GitHubType
    typ          :: ?{String}
    filename     :: ?{String}
    name         :: ?{String}
    path         :: ?{String}
    target       :: ?{String}
    encoding     :: ?{String}
    content      :: ?{String}
    sha          :: ?{String}
    url          :: ?{HTTP.URI}
    git_url      :: ?{HTTP.URI}
    html_url     :: ?{HTTP.URI}
    download_url :: ?{HTTP.URI}
    size         :: ?{Int}
end

Content(data::Dict) = json2github(Content, data)
Content(path::AbstractString) = Content(Dict("path" => path))

name(content::Content) = content.path

###############
# API Methods #
###############

@api_default function file(api::GitHubAPI, repo, path; options...)
    result = gh_get_json(api, content_uri(repo, path); options...)
    return Content(result)
end

@api_default function directory(api::GitHubAPI, repo, path; options...)
    results, page_data = gh_get_paged_json(api, content_uri(repo, path); options...)
    return map(Content, results), page_data
end

@api_default function create_file(api::GitHubAPI, repo, path; options...)
    result = gh_put_json(api, content_uri(repo, path); options...)
    return build_content_response(result)
end

@api_default function update_file(api::GitHubAPI, repo, path; options...)
    result = gh_put_json(api, content_uri(repo, path); options...)
    return build_content_response(result)
end

@api_default function delete_file(api::GitHubAPI, repo, path; options...)
    result = gh_delete_json(api, content_uri(repo, path); options...)
    return build_content_response(result)
end

@api_default function readme(api::GitHubAPI, repo; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/readme"; options...)
    return Content(result)
end

function permalink(content::Content, commit)
    url = string(content.html_url)
    prefix = content.typ == "file" ? "blob" : "tree"
    rgx = Regex(string("/", prefix, "/.*?/"))
    replacement = string("/", prefix, "/", name(commit), "/")
    return HTTP.URI(replace(url, rgx, replacement))
end

###########################
# Content Utility Methods #
###########################

content_uri(repo, path) = "/repos/$(name(repo))/contents/$(name(path))"

function build_content_response(json::Dict)
    results = Dict()
    haskey(json, "commit") && setindex!(results, Commit(json["commit"]), "commit")
    haskey(json, "content") && setindex!(results, Content(json["content"]), "content")
    return results
end
