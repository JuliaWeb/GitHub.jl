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
            haskey(data,  "html_url")  ? HttpCommon.URI(data[ "html_url"]) : nothing,
            haskey(data, "issue_url")  ? HttpCommon.URI(data["issue_url"]) : nothing,
            haskey(data,       "url")  ? HttpCommon.URI(data[      "url"]) : nothing,
            User(get(data, "user", Dict())))
    end
end

# Interface -------

function comments(owner::Owner, repo, issue; auth = AnonymousAuth(), options...)
    comments(auth, owner.login, repo, issue; options...)
end

function comments(owner::AbstractString, repo, issue; auth = AnonymousAuth(), options...)
    comments(auth, owner, repo, issue; options...)
end

function comments(auth::Authorization, owner::AbstractString, repo, issue;
                                                            headers = Dict(),
                                                            query = Dict(),
                                                            result_limit = -1,
                                                            options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/issues/$issue/comments")
    pages = get_pages(uri, result_limit; headers = headers, query = query, options...)
    items = get_items_from_pages(pages)
    return Comment[Comment(i) for i in items]
end
