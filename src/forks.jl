
# Interface -------

function forks(owner, repo; auth = AnonymousAuth(), options...)
    forks(auth, owner, repo; options...)
end

function forks(auth, owner, repo; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/forks");
            headers = headers,
            options...)

    handle_error(r)

    data = JSON.parse(r.data)
end
