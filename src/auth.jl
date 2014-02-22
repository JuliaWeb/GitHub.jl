
# Types -------

abstract Authorization


immutable BasicAuth <: Authorization
    user::String
    password::String
end

function show(io::IO, a::BasicAuth)
    pw_str = repeat("*", 8)
    print(io, "Octokit Authorization ($(a.user), $pw_str))")
end


immutable OAuth2 <: Authorization
    token::String
end

function show(io::IO, a::OAuth2)
    token_str = a.token[1:6] * repeat("*", length(a.token) - 6)
    print(io, "Octokit Authorization ($token_str)")
end


immutable AnonymousAuth <: Authorization
end


# Interface -------

function authenticate(user::String, password::String)
    auth = BasicAuth(user, password)
end

function authenticate(token::String)
    auth = OAuth2(token)

    r = get(API_ENDPOINT; query = { "access_token" => auth.token })
    if r.status < 200 || r.status >= 300
        data = JSON.parse(r.data)
        throw(AuthException(r.status, get(data, "message", ""), get(data, "documentation_url", "")))
    end

    auth
end


# Utility -------

function authenticate_headers(headers, auth::OAuth2)
    headers["Authorization"] = "token $(auth.token)"
end

function authenticate_headers(headers, auth::BasicAuth)
    error("authentication with BasicAuth is not fully supported")
end

function authenticate_headers(headers, auth::AnonymousAuth)
    # nothing to be done
end
