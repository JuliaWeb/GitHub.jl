
# Interface -------

function contributors(owner, repo, attempts = 3; auth = AnonymousAuth(), options...)
    contributors(auth, owner, repo, attempts; options...)
end

function contributors(auth::Authorization, owner, repo, attempts = 3; headers = Dict(), options...)
    authenticate_headers(headers, auth)

    for a in attempts:-1:0
        r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/stats/contributors");
                headers = headers,
                options...)

        handle_error(r)

        if r.status == 200
            return JSON.parse(r.data)
        end

        sleep(2.0)
    end

    throw(GitHubError("Unsuccessfully attempted to retrieve contributors $attempts times."))
end
