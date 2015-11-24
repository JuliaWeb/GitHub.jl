#######################
# Authorization Types #
#######################

abstract Authorization

immutable BasicAuth <: Authorization
    user::GitHubString
    password::GitHubString
end

immutable OAuth2 <: Authorization
    token::GitHubString
end

immutable AnonymousAuth <: Authorization end

###############
# API Methods #
###############

function authenticate(user::AbstractString, password::AbstractString)
    return BasicAuth(user, password)
end

function authenticate(token::AbstractString)
    auth = OAuth2(token)
    r = github_get("/"; params = Dict("access_token" => auth.token))
    handle_response_error(r)
    return auth
end

#########################
# Header Authentication #
#########################

function authenticate_headers!(headers, auth::OAuth2)
    headers["Authorization"] = "token $(auth.token)"
    return headers
end

function authenticate_headers!(headers, auth::BasicAuth)
    error("authentication with BasicAuth is not fully supported")
end

function authenticate_headers!(headers, auth::AnonymousAuth)
    return headers  # nothing to be done
end

###################
# Pretty Printing #
###################

function Base.show(io::IO, a::BasicAuth)
    pw_str = repeat("*", 8)
    print(io, "GitHub Authorization ($(a.user), $pw_str))")
end

function Base.show(io::IO, a::OAuth2)
    token_str = a.token[1:6] * repeat("*", length(a.token) - 6)
    print(io, "GitHub Authorization ($token_str)")
end
