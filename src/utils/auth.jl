#######################
# Authorization Types #
#######################

@compat abstract type Authorization end

immutable OAuth2 <: Authorization
    token::String
end

immutable AnonymousAuth <: Authorization end

immutable JWTAuth <: Authorization
    JWT::String
end

####################
# JWT Construction #
####################

function base64_to_base64url(string)
    replace(replace(replace(string, "=", ""), '+', '-'), '/', '_')
end

function JWTAuth(app_id::Int, priv_key::String; exp_mins = 1)
    algo = base64_to_base64url(base64encode(JSON.json(Dict(
        "alg" => "RS256",
        "typ" => "JWT"
    ))))
    data = base64_to_base64url(base64encode(JSON.json(Dict(
        "iat" => trunc(Int64, Dates.datetime2unix(now(Dates.UTC))),
        "exp" => trunc(Int64, Dates.datetime2unix(now(Dates.UTC)))+exp_mins*60,
        "iss" => app_id
    ))))
    entropy = MbedTLS.Entropy()
    rng = MbedTLS.CtrDrbg()
    MbedTLS.seed!(rng, entropy)
    key = MbedTLS.parse_keyfile(priv_key)
    signature = base64_to_base64url(base64encode(MbedTLS.sign(key, MbedTLS.MD_SHA256,
        MbedTLS.digest(MbedTLS.MD_SHA256, string(algo,'.',data)), rng)))
    JWTAuth(string(algo,'.',data,'.',signature))
end

###############
# API Methods #
###############

function authenticate(token::AbstractString; params = Dict(), options...)
    auth = OAuth2(token)
    params["access_token"] = auth.token
    gh_get("/"; params = params, options...)
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
