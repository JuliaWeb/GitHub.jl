# Types -------

type Comment
    body
    id
    closed_at
    created_at
    updated_at
    html_url
    issue_url
    url
    user

    function Comment(data::Dict)
        new(get(data, "body", nothing),
            get(data, "id", nothing),
            haskey(data,  "closed_at") ? Dates.DateTime(data[ "closed_at"]) : nothing,
            haskey(data, "created_at") ? Dates.DateTime(data["created_at"]) : nothing,
            haskey(data, "updated_at") ? Dates.DateTime(data["updated_at"]) : nothing,
            haskey(data,  "html_url")  ? URI(data[ "html_url"]) : nothing,
            haskey(data, "issue_url")  ? URI(data["issue_url"]) : nothing,
            haskey(data,       "url")  ? URI(data[      "url"]) : nothing,
            User(get(data, "user", Dict())))
    end
end

function show(io::IO, issue::Issue)
    println(io, "$Issue #$(issue.id)")
    for field in names(issue)
        getfield(issue, field)==nothing || println(io, field, ": ", getfield(issue, field))
    end
end


# Interface -------

function comments(owner::Owner, repo, issue; auth = AnonymousAuth(), options...)
    comments(auth, owner.login, repo, issue; options...)
end

function comments(owner::String, repo, issue; auth = AnonymousAuth(), options...)
    comments(auth, owner, repo, issue; options...)
end

function comments(auth::Authorization, owner::String, repo, issue;
                                                            headers = Dict(),
                                                            query = Dict(),
                                                            result_limit = -1,
                                                            options...)
    authenticate_headers(headers, auth)

    pages = get_pages(URI(API_ENDPOINT; path = "/repos/$owner/$repo/issues/$issue/comments"), result_limit;
                      headers = headers,
                      query = query,
                      options...)
    items = get_items_from_pages(pages)
    return Comment[Comment(i) for i in items]
end

