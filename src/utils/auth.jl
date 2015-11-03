
# Types -------

abstract Authorization


immutable BasicAuth <: Authorization
    user::AbstractString
    password::AbstractString
end

function Base.show(io::IO, a::BasicAuth)
    pw_str = repeat("*", 8)
    print(io, "GitHub Authorization ($(a.user), $pw_str))")
end


immutable OAuth2 <: Authorization
    token::AbstractString
end

function Base.show(io::IO, a::OAuth2)
    token_str = a.token[1:6] * repeat("*", length(a.token) - 6)
    print(io, "GitHub Authorization ($token_str)")
end


immutable AnonymousAuth <: Authorization
end


# Interface -------

function authenticate(user::AbstractString, password::AbstractString)
    auth = BasicAuth(user, password)
end

function authenticate(token::AbstractString)
    auth = OAuth2(token)

    r = Requests.get(API_ENDPOINT; query = Compat.@compat Dict("access_token" => auth.token))
    if !(200 <= r.status < 300)
        data = Requests.json(r)
        throw(AuthError(r.status, get(data, "message", ""), get(data, "documentation_url", "")))
    end

    auth
end


# Utility -------

function authenticate_headers!(headers, auth::OAuth2)
    headers["Authorization"] = "token $(auth.token)"
    return headers
end

function authenticate_headers!(headers, auth::BasicAuth)
    error("authentication with BasicAuth is not fully supported")
end

function authenticate_headers!(headers, auth::AnonymousAuth)
    headers  # nothing to be done
end
