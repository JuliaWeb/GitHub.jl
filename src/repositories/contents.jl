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

file(repo, path; options...) = Content(github_get_json(content_uri(repo, path); options...))
directory(repo, path; options...) = map(Content, github_paged_get(content_uri(repo, path); options...))

function create_file(repo, path; options...)
    r = github_put_json(content_uri(repo, path); options...)
    return build_content_response(r)
end

function update_file(repo, path; options...)
    r = github_put_json(content_uri(repo, path); options...)
    return build_content_response(r)
end

function delete_file(repo, path; options...)
    r = github_delete_json(content_uri(repo, path); options...)
    return build_content_response(r)
end

function readme(repo; options...)
    path = "/repos/$(name(repo))/readme"
    return Content(github_get_json(path; options...))
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
