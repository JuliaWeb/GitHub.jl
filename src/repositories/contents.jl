################
# Content Type #
################

type Content <: GitHubType
    typ::Nullable{GitHubString}
    filename::Nullable{GitHubString}
    name::Nullable{GitHubString}
    path::Nullable{GitHubString}
    target::Nullable{GitHubString}
    encoding::Nullable{GitHubString}
    content::Nullable{GitHubString}
    sha::Nullable{GitHubString}
    url::Nullable{HttpCommon.URI}
    git_url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    download_url::Nullable{HttpCommon.URI}
    size::Nullable{Int}
end

Content(data::Dict) = json2github(Content, data)
Content(path::AbstractString) = Content(Dict("path" => path))

namefield(content::Content) = content.path

###############
# API Methods #
###############

function file(repo, path; options...)
    result = gh_get_json(content_uri(repo, path); options...)
    return Content(result)
end

function directory(repo, path; options...)
    results, page_data = gh_get_paged_json(content_uri(repo, path); options...)
    return map(Content, results), page_data
end

function create_file(repo, path; options...)
    result = gh_put_json(content_uri(repo, path); options...)
    return build_content_response(result)
end

function update_file(repo, path; options...)
    result = gh_put_json(content_uri(repo, path); options...)
    return build_content_response(result)
end

function delete_file(repo, path; options...)
    result = gh_delete_json(content_uri(repo, path); options...)
    return build_content_response(result)
end

function readme(repo; options...)
    result = gh_get_json("/repos/$(name(repo))/readme"; options...)
    return Content(result)
end

function permalink(content::Content, commit)
    url = string(get(content.html_url))
    prefix = get(content.typ) == "file" ? "blob" : "tree"
    rgx = Regex(string("/", prefix, "/.*?/"))
    replacement = string("/", prefix, "/", name(commit), "/")
    return HttpCommon.URI(replace(url, rgx, replacement))
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
