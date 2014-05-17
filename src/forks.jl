
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
    map!( r -> Repo(r), data)
end


function fork(owner, repo, organization = ""; auth = AnonymousAuth(), options...)
    fork(auth, owner, repo, organization; options...)
end

function fork(auth, owner, repo, organization = ""; headers = Dict(),
                                                    json = Dict(),
                                                    options...)
    authenticate_headers(headers, auth)

    if organization != ""
        json["organization"] = organization
    end

    r = post(URI(API_ENDPOINT; path = "/repos/$owner/$repo/forks");
            headers = headers,
            json = json,
            options...)

    handle_error(r)

    data = JSON.parse(r.data)
end
