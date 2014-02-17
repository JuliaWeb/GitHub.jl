
# Interface -------

function collaborators(owner, repo; auth = AnonymousAuth(), options...)
    collaborators(auth, owner, repo; options...)
end

function collaborators(auth::Authorization, owner, repo; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/collaborators");
            headers = headers,
            options...)

    handle_error(r)

    data = JSON.parse(r.data)
end
