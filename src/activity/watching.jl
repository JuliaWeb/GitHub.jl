
# Interface -------

function watchers(owner, repo; auth = AnonymousAuth(), options...)
    watchers(auth, owner, repo; options...)
end

function watchers(auth::Authorization, owner, repo; headers = Dict(), result_limit = -1, options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/subscribers")
    pages = get_pages(uri, result_limit; headers = headers, options...)
    items = get_items_from_pages(pages)
    return User[User(i) for i in items]
end


function watched(user; auth = AnonymousAuth(), options...)
    watched(auth, user; options...)
end

function watched(auth::Authorization, user; headers = Dict(), result_limit = -1, options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/users/$user/subscriptions")
    pages = get_pages(uri, result_limit; headers = headers, options...)
    items = get_items_from_pages(pages)
    return Repo[Repo(i) for i in items]
end


function watching(owner, repo; auth = AnonymousAuth(), options...)
    watching(auth, owner, repo; options...)
end

function watching(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/subscription")
    r = Requests.get(uri; headers = headers, options...)
    r.status == 200 && return true
    r.status == 404 && return false
    handle_error(r)  # 404 is not an error in this case
    return false  # who knows... assume no
end


function watch(owner, repo; auth = AnonymousAuth(), options...)
    watch(auth, owner, repo; options...)
end

function watch(auth::Authorization, owner, repo; headers = Dict(),
                                                 query = Dict(),
                                                 subscribed = nothing,
                                                 ignored = nothing,
                                                 options...)
    authenticate_headers!(headers, auth)

    subscribed != nothing && (query["subscribed"] = subscribed)
    ignored != nothing && (query["ignored"] = ignored)

    uri = api_uri("/repos/$owner/$repo/subscription")
    r = Requests.put(headers = headers, query = query, data = "{}", options...)
    handle_error(r)
end


function unwatch(owner, repo; auth = AnonymousAuth(), options...)
    unwatch(auth, owner, repo; options...)
end

function unwatch(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers!(headers, auth)

    uri = api_uri("/repos/$owner/$repo/subscription")
    r = Requests.delete(uri; headers = headers, options...)
    handle_error(r)
end
