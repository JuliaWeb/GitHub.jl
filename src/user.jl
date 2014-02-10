

# Interface -------

function user(username; auth = AnonymousAuth(), options...)
    user(auth, username; options...)
end

function user(auth::Authorization, username; headers = Dict(), options...)
    authenticate_headers(headers, auth)

    r = get(URI(API_ENDPOINT; path = "/users/$username");
            headers = headers,
            options...)

    handle_error(r)

    data = JSON.parse(r.data)
end
