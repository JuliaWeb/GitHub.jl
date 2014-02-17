
# Interface -------

function watchers(owner, repo; auth = AnonymousAuth(), options...)
    watchers(auth, owner, repo; options...)
end

function watchers(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/subscribers");
            headers = headers,
            options...)

    handle_error(r)

    data = JSON.parse(r.data)
end