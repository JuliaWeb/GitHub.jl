
# Interface -------

function stargazers(owner, repo; auth = AnonymousAuth(), options...)
    stargazers(auth, owner, repo; options...)
end

function stargazers(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/stargazers");
            headers = headers,
            options...)

    handle_error(r)

    data = JSON.parse(r.data)
end


function starred(user; auth = AnonymousAuth(), options...)
    starred(auth, user; options...)
end

function starred(auth::Authorization, user; headers = Dict(),
                                            query = Dict(),
                                            sort = nothing,
                                            direction = nothing,
                                            options...)
    authenticate_headers(headers, auth)

    sort != nothing && (query["sort"] = sort)
    direction != nothing && (query["direction"] = direction)

    r = get(URI(API_ENDPOINT; path = "/users/$user/starred"); query = query, options...)

    handle_error(r)

    data = JSON.parse(r.data)
end
