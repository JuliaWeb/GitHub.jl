
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
