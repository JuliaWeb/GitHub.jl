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

"""
    JWTAuth(app_id::Int, privkey; iat = now(Dates.UTC), exp_mins = 1)

Create a JWT for authenticating as the GitHub App `app_id`. `privkey` is the
app's RSA private key, given as one of:

- the path to a PEM- or DER-encoded key file;
- the PEM text itself;
- the PEM or DER encoding as bytes;
- an [`RSAPrivateKey`](@ref), to parse the key once and reuse it for many JWTs.
"""
function JWTAuth(app_id::Int, privkey::RSAPrivateKey; iat = now(Dates.UTC), exp_mins = 1)
    algo = base64_to_base64url(base64encode("{\"typ\":\"JWT\",\"alg\":\"RS256\"}"))

    jwt_iat = trunc(Int64, Dates.datetime2unix(iat))
    jwt_exp = trunc(Int64, Dates.datetime2unix(iat+Dates.Minute(exp_mins)))
    data = base64_to_base64url(base64encode("{\"exp\":$(jwt_exp),\"iat\":$(jwt_iat),\"iss\":$(app_id)}"))

    signature = base64_to_base64url(base64encode(rsa_sha256_sign(privkey, string(algo,'.',data))))
    JWTAuth(string(algo,'.',data,'.',signature))
end

function JWTAuth(app_id::Int, privkey::Union{AbstractString, AbstractVector{UInt8}}; kwargs...)
    key = _private_key(privkey)
    try
        return JWTAuth(app_id, key; kwargs...)
    finally
        _free!(key)
    end
end

# Accept a path to a PEM or DER file, the PEM text itself, or the PEM/DER bytes.
_private_key(privkey::AbstractVector{UInt8}) = RSAPrivateKey(privkey)

function _private_key(privkey::AbstractString)
    if occursin("PRIVATE KEY", privkey)
        return RSAPrivateKey(privkey)
    elseif _isfile_nothrow(privkey)
        return RSAPrivateKey(read(privkey))
    else
        throw(ArgumentError(
            "privkey must be the path to a PEM- or DER-encoded RSA private key file, or the PEM text itself"))
    end
end

# `isfile` throws instead of returning `false` for strings that cannot be a path,
# e.g. a base64-encoded key (`ENAMETOOLONG`) or one containing NUL bytes.
function _isfile_nothrow(path::AbstractString)
    try
        return isfile(path)
    catch err
        err isa Union{Base.IOError, ArgumentError} || rethrow()
        return false
    end
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
