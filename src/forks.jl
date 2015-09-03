
# Interface -------

function forks(owner, repo; auth = AnonymousAuth(), options...)
    forks(auth, owner, repo; options...)
end

function forks(auth, owner, repo; headers = Dict(), result_limit = -1, options...)
    authenticate_headers(headers, auth)
    pages = get_pages(URI(API_ENDPOINT; path = "/repos/$owner/$repo/forks"), result_limit;
                      headers = headers,
                      options...)
    items = get_items_from_pages(pages)
    return Repo[Repo(i) for i in items]
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

    data = Requests.json(r)
end
