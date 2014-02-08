
abstract Authorization


immutable BasicAuth <: Authorization
    user::String
    password::String
end


immutable OAuth2 <: Authorization
    token::String
end


immutable AnonymousAuth <: Authorization
end

# -------

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
