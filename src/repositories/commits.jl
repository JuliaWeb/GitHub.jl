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
