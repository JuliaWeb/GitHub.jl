# GET /repos/:owner/:repo/contents/:path

# need new type: FILE
  # - if file, then file...
  # - if directory, then list of files??


type File
    encoding
    size
    name
    path
    content
    sha
    url
    git_url
    html_url
    download_url
    _links
    object_type


    function File(data::Dict)
        new(get(data, "encoding", nothing),
            get(data, "size", nothing),
            get(data, "name", nothing),
            get(data, "path", nothing),
            decodeContent(get(data, "content", nothing)),
            get(data, "sha", nothing),
            get(data, "url", nothing),
            get(data, "git_url", nothing),
            get(data, "html_url", nothing),
            get(data, "download_url", nothing),
            get(data, "_links", nothing),
            get(data, "type", nothing))
    end

    function decodeContent(content)
      content == nothing && return nothing
      return join([bytestring(decode(Base64, line)) for line in
                  split(content, '\n')], "")
    end

    function File(data::Array)
      [File(file) for file in data]
    end

    # add get_data method; handle base64
end

type Commit
    _links
    name
    html_url
    sha
    git_url
    size
    download_url
    url
    path
    committer
    author
    parents
    message
    tree
    object_type

    function Commit(data::Dict)
        new(get(data, "_links", nothing),
            get(data, "name", nothing),
            get(data, "html_url", nothing),
            get(data, "sha", nothing),
            get(data, "git_url", nothing),
            get(data, "size", nothing),
            get(data, "download_url", nothing),
            get(data, "url", nothing),
            get(data, "path", nothing),
            User(get(data, "committer", nothing)),
            User(get(data, "author", nothing)),
            get(data, "parents", nothing),
            get(data, "message", nothing),
            get(data, "tree", nothing),
            get(data, "type", nothing))
    end

end


# function contents(repo::Repo; auth = AnonymousAuth(), options...)
#   contents(auth, repo.owner.login, repo.name; options...)
# end
#
# function contents(owner::Owner, repo; auth = AnonymousAuth(), options...)
#   contents(auth, owner.login, repo; options...)
# end
#
# function contents(owner, repo; auth = AnonymousAuth(), path = "", options...)
#   contents(auth, owner, repo; options...)
# end

function contents(auth::Authorization, owner::String, repo::String;
                    path::String = "", headers = Dict(), ref = nothing,
                    options...)
    authenticate_headers(headers, auth)
    query = Dict()
    ref == nothing || (query["ref"] = ref)
    r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/contents/$path");
                    headers = headers, query = query, options...)
    handle_error(r)
    return File(JSON.parse(r.data))
end

function create_file(auth::Authorization, owner::String, repo::String,
                    path::String, message::String, content; headers = Dict(),
                    branch::String = nothing, author = nothing,
                    committer = nothing, options...)
      data = {"message"=> message, "content"=> content,
              "author"=> author, "committer"=> committer, "branch" => branch}
  return upload_file(auth, owner, repo, path, data, headers)
end


function update_file(auth::Authorization, owner::String, repo::String,
                    path::String, message::String, sha::String, content;
                    author::User = User({"name"=> "NA", "email"=>"NA"}),
                    committer::User = User({"name"=> "NA", "email"=>"NA"}),
                    headers = Dict(), branch = nothing)
    data = {"message"=> message, "content"=> content,
            "author"=> author, "committer"=> committer,
            "sha"=> sha, "branch" => branch}
  return upload_file(auth, owner, repo, path, data, headers)
end

function upload_file(auth::Authorization, owner::String, repo::String,
                    path::String, data, headers)
    for (k,v) in data
      v == nothing && delete!(data, k)
    end
    data["content"] = bytestring(encode(Base64, JSON.json(data["content"])))
    authenticate_headers(headers, auth)
    r = put(URI(API_ENDPOINT; path = "/repos/$owner/$repo/contents/$path"),
            json=data; headers = headers)
    handle_error(r)
    resp = JSON.parse(r.data)
    return {"content" => File(get(resp, "content", nothing)),
            "commit" => Commit(get(resp, "commit", nothing))}
end


function delete_file(auth::Authorization, owner::String, repo::String,
                path::String, sha::String, message::String; branch = "default",
                headers = Dict(), author::User = User({"name"=> "NA", "email"=>"NA"}),
                committer::User = User({"name"=> "NA", "email"=>"NA"}))
    data = {"message" => message, "sha" => sha}
    branch == "default" || (data["branch"] = branch)
    author.name == "NA" || (data["author"] = author)
    committer.name == "NA" || (data["committer"] = committer)
    authenticate_headers(headers, auth)
    r = Requests.delete(URI(API_ENDPOINT;
            path = "/repos/$owner/$repo/contents/$path"),
            json=data, headers = headers)
    handle_error(r)
    # print(get(JSON.parse(r.data), "commit", nothing))
    return Commit(get(JSON.parse(r.data), "commit", nothing))
end


function readme(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/readme");
                    headers = headers)
    handle_error(r)
    readme_file = File(JSON.parse(r.data))
    return readme_file
end

## Issues
#4) need to add get data method to files with links...
#5) need to fix some fields in files & commit types
#6) Implement Owner, etc classes in new functions
