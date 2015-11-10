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
      return join([bytestring(base64decode(line)) for line in
                  split(content, '\n')], "")
    end

    function File(data::Array)
      [File(file) for file in data]
    end

    # add get_data method; handle base64
end


function contents(repo::Repo; auth = AnonymousAuth(), options...)
  contents(auth, repo.owner.login, repo.name; options...)
end

function contents(owner::Owner, repo; auth = AnonymousAuth(), options...)
  contents(auth, owner.login, repo; options...)
end

function contents(owner, repo; auth = AnonymousAuth(), path = "", options...)
  contents(auth, owner, repo; options...)
end

function contents(auth::Authorization, owner::AbstractString, repo::AbstractString;
                    path::AbstractString = "", headers = Dict(), ref = nothing,
                    options...)
    authenticate_headers!(headers, auth)
    query = Dict()
    ref == nothing || (query["ref"] = ref)
    uri = api_uri("/repos/$owner/$repo/contents/$path")
    r = Requests.get(uri; headers = headers, query = query, options...)
    handle_error(r)
    return File(Requests.json(r))
end


function create_file(auth::Authorization, owner::AbstractString, repo::AbstractString,
                    path::AbstractString, message::AbstractString, content; headers = Dict(),
                    branch = nothing, author = nothing,
                    committer = nothing, options...)
      data = Dict("message" => message, "content" => content,
                  "author" => author, "committer" => committer,
                  "branch" => branch)
  return upload_file(auth, owner, repo, path, data, headers)
end


function update_file(auth::Authorization, owner::AbstractString, repo::AbstractString,
                     path::AbstractString, sha::AbstractString, message::AbstractString, content;
                     author::User = User(Dict("name"=> "NA", "email"=>"NA")),
                     committer::User = User(Dict("name"=> "NA", "email"=>"NA")),
                     headers = Dict(), branch = nothing)
    data = Dict("message"=> message, "content"=> content,
                "author"=> author, "committer"=> committer,
                "sha"=> sha, "branch" => branch)
  return upload_file(auth, owner, repo, path, data, headers)
end


function upload_file(auth::Authorization, owner::AbstractString, repo::AbstractString,
                     path::AbstractString, data, headers)
    for (k,v) in data
      v == nothing && delete!(data, k)
    end
    data["content"] = bytestring(base64encode(JSON.json(data["content"])))
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/contents/$path")
    r = Requests.put(uri, json=data; headers = headers)
    handle_error(r)
    resp = Requests.json(r)
    return Dict("content" => File(get(resp, "content", nothing)),
                "commit" => Commit(get(resp, "commit", nothing)))
end


function delete_file(auth::Authorization, owner::AbstractString, repo::AbstractString,
                     path::AbstractString, sha::AbstractString, message::AbstractString;
                     branch = "default", headers = Dict(),
                     author::User = User(Dict("name"=> "NA", "email"=>"NA")),
                     committer::User = User(Dict("name"=> "NA", "email"=>"NA")))
    data = Dict("message" => message, "sha" => sha)
    branch == "default" || (data["branch"] = branch)
    author.name == "NA" || (data["author"] = author)
    committer.name == "NA" || (data["committer"] = committer)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/contents/$path")
    r = Requests.delete(uri; json=data, headers = headers)
    handle_error(r)
    return Commit(get(Requests.json(r), "commit", nothing))
end


function readme(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/readme")
    r = Requests.get(uri; headers = headers, options...)
    handle_error(r)
    readme_file = File(Requests.json(r))
    return readme_file
end
