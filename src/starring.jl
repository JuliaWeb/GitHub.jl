
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
    map!( u -> User(u), data)
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

    r = get(URI(API_ENDPOINT; path = "/users/$user/starred"); query = query,
                                                              headers = headers,
                                                              options...)
    handle_error(r)

    data = JSON.parse(r.data)
    map!( u -> Repo(u), data)
end


function star(owner, repo; auth = AnonymousAuth(), options...)
    star(auth, owner, repo; options...)
end

function star(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers(headers, auth)

    r = put(URI(API_ENDPOINT; path = "/user/starred/$owner/$repo"); headers = headers,
                                                                    options...)
    handle_error(r)
end


function unstar(owner, repo; auth = AnonymousAuth(), options...)
    unstar(auth, owner, repo; options...)
end

function unstar(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers(headers, auth)

    r = delete(URI(API_ENDPOINT; path = "/user/starred/$owner/$repo"); headers = headers,
                                                                       options...)
    handle_error(r)
end



