#######################
# Authorization Types #
#######################

abstract type Authorization end

struct OAuth2 <: Authorization
    token::String
end

struct AnonymousAuth <: Authorization end

struct JWTAuth <: Authorization
    JWT::String
end

####################
# JWT Construction #
####################

function base64_to_base64url(string)
    replace(replace(replace(string, "=", ""), '+', '-'), '/', '_')
end

function JWTAuth(app_id::Int, key::MbedTLS.PKContext; iat = now(Dates.UTC), exp_mins = 1)
    algo = base64_to_base64url(base64encode(JSON.json(Dict(
        "alg" => "RS256",
        "typ" => "JWT"
    ))))
    data = base64_to_base64url(base64encode(JSON.json(Dict(
        "iat" => trunc(Int64, Dates.datetime2unix(iat)),
        "exp" => trunc(Int64, Dates.datetime2unix(iat+Dates.Minute(exp_mins))),
        "iss" => app_id
    ))))
    signature = base64_to_base64url(base64encode(MbedTLS.sign(key, MbedTLS.MD_SHA256,
        MbedTLS.digest(MbedTLS.MD_SHA256, string(algo,'.',data)), RNG[])))
    JWTAuth(string(algo,'.',data,'.',signature))
end

function JWTAuth(app_id::Int, privkey::String; kwargs...)
    JWTAuth(app_id, MbedTLS.parse_keyfile(privkey); kwargs...)
end

###############
# API Methods #
###############

@api_default function authenticate(api::GitHubAPI, token::AbstractString; params = Dict(), options...)
    auth = OAuth2(token)
    params["access_token"] = auth.token
    gh_get(api, "/"; params = params, options...)
    return auth
end

#########################
# Header Authentication #
#########################

authenticate_headers!(headers, auth::AnonymousAuth) = headers

function authenticate_headers!(headers, auth::OAuth2)
    headers["Authorization"] = "token $(auth.token)"
    return headers
end

function authenticate_headers!(headers, auth::JWTAuth)
    headers["Authorization"] = "Bearer $(auth.JWT)"
    return headers
end


###################
# Pretty Printing #
###################

function Base.show(io::IO, a::OAuth2)
    token_str = a.token[1:6] * repeat("*", length(a.token) - 6)
    print(io, "GitHub.OAuth2($token_str)")
end
