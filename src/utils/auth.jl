#######################
# Authorization Types #
#######################

abstract type Authorization end

# TODO: SecureString on 0.7
struct OAuth2 <: Authorization
    token::String
    function OAuth2(token)
        token = convert(String, token)
        if !all(c->isascii(c) && !isspace(c), token)
            throw(ArgumentError("token `$token` has invalid whitespace or non-ascii character."))
        end
        new(token)
    end
end

struct UsernamePassAuth <: Authorization
    username::String
    password::String
end

struct AnonymousAuth <: Authorization end

struct JWTAuth <: Authorization
    JWT::String
    function JWTAuth(token)
        token = convert(String, token)
        if !all(c->isascii(c) && !isspace(c), token)
            throw(ArgumentError("ArgumentError token `$token` has invalid whitespace or non-ascii character."))
        end
        new(token)
    end
end

####################
# JWT Construction #
####################

function base64_to_base64url(string)
    replace(replace(replace(string, "=" => ""), '+' => '-'), '/' => '_')
end

function JWTAuth(app_id::Int, key::MbedTLS.PKContext; iat = now(Dates.UTC), exp_mins = 1)
    algo = base64_to_base64url(base64encode("{\"typ\":\"JWT\",\"alg\":\"RS256\"}"))

    jwt_iat = trunc(Int64, Dates.datetime2unix(iat))
    jwt_exp = trunc(Int64, Dates.datetime2unix(iat+Dates.Minute(exp_mins)))
    data = base64_to_base64url(base64encode("{\"exp\":$(jwt_exp),\"iat\":$(jwt_iat),\"iss\":$(app_id)}"))

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

@api_default function authenticate(api::GitHubAPI, token::AbstractString; options...)
    auth = OAuth2(token)
    gh_get(api, "/"; auth = auth, options...)
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

function authenticate_headers!(headers, auth::UsernamePassAuth)
    headers["Authorization"] = "Basic $(base64encode(string(auth.username, ':', auth.password)))"
    return headers
end

###################
# Pretty Printing #
###################

function Base.show(io::IO, a::OAuth2)
    token_str = a.token[1:6] * repeat("*", length(a.token) - 6)
    print(io, "GitHub.OAuth2($token_str)")
end

###########
# Hashing #
###########

# These are used to implement the 1s mutation delay on a per-auth basis
# See also `wait_for_mutation_delay`. We want it to be difficult to
# invert the hash to recover the token, as the hash is stored in a global dict
# in this module.
let
    salt = randstring(RandomDevice(), 20)
    global uint64_hash(str::AbstractString) = first(reinterpret(UInt64, sha256(string(salt, str))[1:8]))
end

get_auth_hash(auth::OAuth2) = uint64_hash(auth.token)

get_auth_hash(auth::UsernamePassAuth) = uint64_hash(string(auth.username, "##", auth.password))

get_auth_hash(::AnonymousAuth) = UInt64(0)

# note this will give different hashes for different JWTs from the same key,
# meaning in that case the 1s mutation delay will apply per-JWT instead of per-key
get_auth_hash(auth::JWTAuth) = uint64_hash(auth.JWT)
