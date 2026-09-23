# Minimal RSA signing via libcrypto from OpenSSL_jll.
#
# Used to sign GitHub App JWTs (RS256, i.e. RSASSA-PKCS1-v1_5 over SHA-256).
# OpenSSL_jll is already part of the dependency tree through HTTP.jl.

import OpenSSL_jll: libcrypto

struct OpenSSLError <: Exception
    context::String
    msg::String
end

Base.showerror(io::IO, e::OpenSSLError) = print(io, "OpenSSLError in ", e.context, ": ", e.msg)

# libcrypto keeps a per-thread error queue. Every entry point below clears it
# first, so that an error left behind by some other libcrypto user (e.g. the
# HTTP.jl TLS backend) is not reported as ours.
_clear_openssl_errors() = @ccall libcrypto.ERR_clear_error()::Cvoid

# Drain the whole error queue (oldest first): a single failure typically pushes
# several entries, and the most descriptive one is usually the last (e.g. "PEM
# routines::bad password read" after a couple of "interrupted or cancelled").
function _throw_openssl_error(context::AbstractString)
    msgs = String[]
    buf = Vector{UInt8}(undef, 256)
    while (code = @ccall libcrypto.ERR_get_error()::Culong) != 0
        @ccall libcrypto.ERR_error_string_n(code::Culong, buf::Ptr{UInt8}, length(buf)::Csize_t)::Cvoid
        push!(msgs, GC.@preserve buf unsafe_string(pointer(buf)))
    end
    throw(OpenSSLError(String(context), isempty(msgs) ? "unknown error" : join(msgs, "; ")))
end

# Password callback for `PEM_read_bio_*`. Encrypted keys are not supported, so
# refuse (-1) instead of letting OpenSSL's default callback prompt on the
# terminal, which would block a server process.
_pem_no_password_cb(::Ptr{UInt8}, ::Cint, ::Cint, ::Ptr{Cvoid})::Cint = Cint(-1)

function _check_not_encrypted_pem(pem::AbstractString)
    # "-----BEGIN ENCRYPTED PRIVATE KEY-----" (PKCS#8) or a legacy
    # "Proc-Type: 4,ENCRYPTED" header (OpenSSL tolerates whitespace around its fields).
    # Match the markers rather than the bare word, which could also occur inside the
    # base64 body.
    if occursin("-----BEGIN ENCRYPTED", pem) || occursin(r"Proc-Type:\s*4\s*,\s*ENCRYPTED", pem)
        throw(ArgumentError(
            "Encrypted private keys are not supported. Decrypt the key first, e.g. " *
            "`openssl pkey -in key.pem -out key-decrypted.pem`."))
    end
    return nothing
end

# `PEM_read_bio_PrivateKey` / `PEM_read_bio_PUBKEY` behind one call shape, so that
# `_read_pem_key` can take either (`@ccall` needs the literal symbol).
_pem_read_private_key(bio::Ptr{Cvoid}, password_cb::Ptr{Cvoid}) =
    @ccall libcrypto.PEM_read_bio_PrivateKey(
        bio::Ptr{Cvoid}, C_NULL::Ptr{Cvoid}, password_cb::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::Ptr{Cvoid}
_pem_read_public_key(bio::Ptr{Cvoid}, password_cb::Ptr{Cvoid}) =
    @ccall libcrypto.PEM_read_bio_PUBKEY(
        bio::Ptr{Cvoid}, C_NULL::Ptr{Cvoid}, password_cb::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::Ptr{Cvoid}

# Read a PEM-encoded key into an `EVP_PKEY*` with `reader` (one of the two above);
# `context` names the libcrypto function in the error. Caller must `EVP_PKEY_free`.
function _read_pem_key(pem::AbstractString, reader::F, context::String) where {F}
    _clear_openssl_errors()
    # `BIO_new_mem_buf` does not copy the buffer, so `pem_str` must be kept alive
    # for as long as the BIO is read from.
    pem_str = String(pem)
    password_cb = @cfunction(_pem_no_password_cb, Cint, (Ptr{UInt8}, Cint, Cint, Ptr{Cvoid}))
    GC.@preserve pem_str begin
        bio = @ccall libcrypto.BIO_new_mem_buf(pem_str::Ptr{UInt8}, sizeof(pem_str)::Cint)::Ptr{Cvoid}
        bio == C_NULL && _throw_openssl_error("BIO_new_mem_buf")
        try
            pkey = reader(bio, password_cb)
            pkey == C_NULL && _throw_openssl_error(context)
            return pkey
        finally
            @ccall libcrypto.BIO_free(bio::Ptr{Cvoid})::Cint
        end
    end
end

# Parse a PEM-encoded private key into an `EVP_PKEY*`. Caller must `EVP_PKEY_free`.
function _load_private_key_pem(pem::AbstractString)
    _check_not_encrypted_pem(pem)
    # Name the public-key case (as the DER path does) instead of surfacing OpenSSL's
    # bare "DECODER routines::unsupported".
    if occursin("PUBLIC KEY-----", pem) && !_pem_has_private_key(pem)
        throw(ArgumentError("The PEM data is a public key; RS256 signing requires the RSA private key"))
    end
    return _read_pem_key(pem, _pem_read_private_key, "PEM_read_bio_PrivateKey")
end

_pem_has_private_key(pem::AbstractString) = occursin("PRIVATE KEY-----", pem)

# `EVP_DigestSign*` signs with whatever key type it is given, so an EC key would
# silently yield an ECDSA signature in a JWT whose header claims RS256. Reject
# non-RSA keys. RSA-PSS keys (`EVP_PKEY_RSA_PSS`) must be rejected too: they are
# restricted to PSS padding, so they would yield a (randomized) PS256 signature.
# `EVP_PKEY_get0_RSA` cannot tell the two apart, so compare the base key type.
# That function is exported as `EVP_PKEY_base_id` by OpenSSL 1.1 but as
# `EVP_PKEY_get_base_id` by 3.x (where the old name is only a macro), so look up
# whichever symbol this libcrypto has.
const _EVP_PKEY_RSA = Cint(6)  # NID_rsaEncryption

# Resolved lazily at runtime (a function pointer cannot be baked into the
# precompile cache) and cached, so that the symbol lookup happens once per session
# rather than on every key parse.
const _pkey_base_id_fptr = Ref{Ptr{Cvoid}}(C_NULL)

function _pkey_base_id(pkey::Ptr{Cvoid})
    fptr = _pkey_base_id_fptr[]
    if fptr == C_NULL
        lib = Libc.Libdl.dlopen(libcrypto)
        fptr = Libc.Libdl.dlsym(lib, :EVP_PKEY_get_base_id; throw_error = false)
        fptr === nothing && (fptr = Libc.Libdl.dlsym(lib, :EVP_PKEY_base_id))
        _pkey_base_id_fptr[] = fptr
    end
    return ccall(fptr, Cint, (Ptr{Cvoid},), pkey)
end

# Check the key type, freeing `pkey` if it is rejected, so that callers can take
# ownership of the returned pointer unconditionally.
function _checked_rsa_key(pkey::Ptr{Cvoid})
    if _pkey_base_id(pkey) != _EVP_PKEY_RSA
        @ccall libcrypto.EVP_PKEY_free(pkey::Ptr{Cvoid})::Cvoid
        _clear_openssl_errors()
        throw(ArgumentError("RS256 requires an RSA (not RSA-PSS) key"))
    end
    return pkey
end

# A PKCS#8 `EncryptedPrivateKeyInfo` is a SEQUENCE whose first element is the
# encryption `AlgorithmIdentifier` (another SEQUENCE, tag 0x30), whereas unencrypted
# PKCS#1 and PKCS#8 keys start with a version INTEGER (tag 0x02). Detect the former
# so that it gets the same clear error as an encrypted PEM key. A DER
# `SubjectPublicKeyInfo` (a public key) has the same shape, so name that case too
# rather than misreporting it as encrypted.
function _check_not_encrypted_der(der::Vector{UInt8})
    length(der) >= 2 || return nothing
    # Skip the outer SEQUENCE header: short-form length, or 0x8n + n length bytes.
    hdr = der[2] < 0x80 ? 2 : 2 + Int(der[2] & 0x7f)
    if length(der) > hdr && der[hdr + 1] == 0x30
        throw(ArgumentError(
            "Not an unencrypted private key: the DER data is an encrypted (PKCS#8) " *
            "private key or a public key. Encrypted keys are not supported; decrypt " *
            "the key first, e.g. `openssl pkey -inform DER -in key.der -out key-decrypted.pem`."))
    end
    return nothing
end

# Parse a DER-encoded private key (PKCS#1 or PKCS#8) into an `EVP_PKEY*`. Caller
# must `EVP_PKEY_free`.
function _load_private_key_der(der::Vector{UInt8})
    _check_not_encrypted_der(der)
    _clear_openssl_errors()
    pkey = GC.@preserve der begin
        # `d2i_AutoPrivateKey` advances the pointer it is given, so pass a copy.
        p = Ref{Ptr{UInt8}}(pointer(der))
        @ccall libcrypto.d2i_AutoPrivateKey(C_NULL::Ptr{Cvoid}, p::Ref{Ptr{UInt8}}, length(der)::Clong)::Ptr{Cvoid}
    end
    pkey == C_NULL && _throw_openssl_error("d2i_AutoPrivateKey")
    return pkey
end

# Marker for the internal constructor below.
struct _TakeOwnership end

"""
    RSAPrivateKey(key)

An RSA private key parsed once, so that it can be reused for many signatures
(e.g. for [`JWTAuth`](@ref)) without re-reading and re-parsing it each time.
`key` is the PEM text or the path to a PEM- or DER-encoded key file as a
string, or the PEM or DER encoding as bytes.
Encrypted keys and non-RSA keys (including RSA-PSS) are rejected.
"""
mutable struct RSAPrivateKey
    ptr::Ptr{Cvoid}
    # Only called by `_wrap_rsa_key`, which has checked the key type and transfers
    # ownership of `ptr`; a public `Ptr` constructor would let two objects own (and
    # free) the same `EVP_PKEY`.
    function RSAPrivateKey(::_TakeOwnership, ptr::Ptr{Cvoid})
        key = new(ptr)
        finalizer(_free!, key)
        return key
    end
end

function _free!(key::RSAPrivateKey)
    ptr, key.ptr = key.ptr, C_NULL
    ptr != C_NULL && @ccall libcrypto.EVP_PKEY_free(ptr::Ptr{Cvoid})::Cvoid
    return nothing
end

function RSAPrivateKey(key::AbstractString)
    occursin("-----BEGIN", key) && return _wrap_rsa_key(_load_private_key_pem(key))
    _isfile_nothrow(key) && return _rsa_key_from_bytes!(read(key))
    throw(ArgumentError(
        "key must be the path to a PEM- or DER-encoded RSA private key file, or the PEM text itself"))
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

# The caller's vector is copied once here; `_rsa_key_from_bytes!` then owns it.
RSAPrivateKey(key::AbstractVector{UInt8}) = _rsa_key_from_bytes!(Vector{UInt8}(key))

# Takes ownership of `key` (`String(::Vector{UInt8})` empties the buffer).
function _rsa_key_from_bytes!(key::Vector{UInt8})
    # DER starts with an ASN.1 SEQUENCE tag; PEM with "-----BEGIN" (or whitespace).
    pkey = if !isempty(key) && first(key) == 0x30
        _load_private_key_der(key)
    else
        _load_private_key_pem(String(key))
    end
    return _wrap_rsa_key(pkey)
end

_wrap_rsa_key(pkey::Ptr{Cvoid}) = RSAPrivateKey(_TakeOwnership(), _checked_rsa_key(pkey))

# Parse `key` into a temporary `RSAPrivateKey`, pass it to `f`, and free it
# straight away rather than waiting for GC.
function _with_private_key(f, key)
    k = RSAPrivateKey(key)
    try
        return f(k)
    finally
        _free!(k)
    end
end

Base.show(io::IO, ::RSAPrivateKey) = print(io, "GitHub.RSAPrivateKey(<redacted>)")

# The default `deepcopy` would duplicate the raw pointer, and the two finalizers
# would then free the same `EVP_PKEY` twice. Share the OpenSSL object through its
# reference count instead.
function Base.deepcopy_internal(key::RSAPrivateKey, dict::IdDict)
    haskey(dict, key) && return dict[key]::RSAPrivateKey
    ptr = key.ptr
    if ptr != C_NULL
        rc = @ccall libcrypto.EVP_PKEY_up_ref(ptr::Ptr{Cvoid})::Cint
        rc == 1 || _throw_openssl_error("EVP_PKEY_up_ref")
    end
    return dict[key] = RSAPrivateKey(_TakeOwnership(), ptr)
end

# Load either a PEM private key or a PEM public key. Caller must `EVP_PKEY_free`.
function _load_key_pem_any(pem::AbstractString)
    _pem_has_private_key(pem) && return _load_private_key_pem(pem)
    return _read_pem_key(pem, _pem_read_public_key, "PEM_read_bio_PUBKEY")
end

"""
    rsa_sha256_sign(key, data) -> Vector{UInt8}

Sign `data` (a `String` or byte vector) with the RSA private `key`, given as an
[`RSAPrivateKey`](@ref) or in any form `RSAPrivateKey` accepts, producing an
RSASSA-PKCS1-v1_5 signature over the SHA-256 digest of `data`. This is the
`RS256` algorithm used for GitHub App JWTs.
"""
rsa_sha256_sign(key, data::AbstractString) = rsa_sha256_sign(key, codeunits(data))

rsa_sha256_sign(key::Union{AbstractString, AbstractVector{UInt8}}, data::AbstractVector{UInt8}) =
    _with_private_key(k -> rsa_sha256_sign(k, data), key)

function rsa_sha256_sign(key::RSAPrivateKey, data::AbstractVector{UInt8})
    # libcrypto needs a contiguous buffer; this is a no-op for a `Vector{UInt8}`.
    data = convert(Vector{UInt8}, data)
    pkey = key.ptr
    # The pointer is also NULL for a key restored from a precompile cache or by
    # `deserialize`, which do not carry the OpenSSL object over.
    pkey == C_NULL && throw(ArgumentError(
        "RSAPrivateKey has been freed or deserialized; create it at runtime " *
        "(e.g. in the module's `__init__`) instead of storing it in a precompiled constant"))
    _clear_openssl_errors()
    ctx = C_NULL
    GC.@preserve key try
        ctx = @ccall libcrypto.EVP_MD_CTX_new()::Ptr{Cvoid}
        ctx == C_NULL && _throw_openssl_error("EVP_MD_CTX_new")
        md = @ccall libcrypto.EVP_sha256()::Ptr{Cvoid}
        md == C_NULL && _throw_openssl_error("EVP_sha256")
        rc = @ccall libcrypto.EVP_DigestSignInit(
            ctx::Ptr{Cvoid}, C_NULL::Ptr{Ptr{Cvoid}}, md::Ptr{Cvoid}, C_NULL::Ptr{Cvoid}, pkey::Ptr{Cvoid})::Cint
        rc == 1 || _throw_openssl_error("EVP_DigestSignInit")
        # NOTE: use `EVP_DigestUpdate` rather than `EVP_DigestSignUpdate`: the latter is
        # only a macro alias in OpenSSL 1.x and is not an exported symbol there.
        rc = @ccall libcrypto.EVP_DigestUpdate(ctx::Ptr{Cvoid}, data::Ptr{UInt8}, length(data)::Csize_t)::Cint
        rc == 1 || _throw_openssl_error("EVP_DigestUpdate (sign)")
        # First call with a NULL buffer queries the required signature length.
        siglen = Ref{Csize_t}(0)
        rc = @ccall libcrypto.EVP_DigestSignFinal(ctx::Ptr{Cvoid}, C_NULL::Ptr{UInt8}, siglen::Ref{Csize_t})::Cint
        rc == 1 || _throw_openssl_error("EVP_DigestSignFinal (length query)")
        sig = Vector{UInt8}(undef, siglen[])
        rc = @ccall libcrypto.EVP_DigestSignFinal(ctx::Ptr{Cvoid}, sig::Ptr{UInt8}, siglen::Ref{Csize_t})::Cint
        rc == 1 || _throw_openssl_error("EVP_DigestSignFinal")
        resize!(sig, siglen[])
        return sig
    finally
        ctx != C_NULL && @ccall libcrypto.EVP_MD_CTX_free(ctx::Ptr{Cvoid})::Cvoid
    end
end

"""
    rsa_sha256_verify(key_pem::AbstractString, data, signature) -> Bool

Verify an `RS256` signature produced by [`rsa_sha256_sign`](@ref). Accepts either
a PEM public key or a PEM private key (whose public part is used).
"""
rsa_sha256_verify(key_pem::AbstractString, data::AbstractString, signature::AbstractVector{UInt8}) =
    rsa_sha256_verify(key_pem, codeunits(data), signature)

function rsa_sha256_verify(key_pem::AbstractString, data::AbstractVector{UInt8}, signature::AbstractVector{UInt8})
    data = convert(Vector{UInt8}, data)
    signature = convert(Vector{UInt8}, signature)
    # Reject non-RSA keys here too: with an EC key `EVP_DigestVerifyFinal` fails with
    # an empty error queue ("unknown error"), and an RSA-PSS key would silently
    # verify PSS signatures instead of RS256 ones.
    pkey = _checked_rsa_key(_load_key_pem_any(key_pem))
    _clear_openssl_errors()
    ctx = C_NULL
    try
        ctx = @ccall libcrypto.EVP_MD_CTX_new()::Ptr{Cvoid}
        ctx == C_NULL && _throw_openssl_error("EVP_MD_CTX_new")
        md = @ccall libcrypto.EVP_sha256()::Ptr{Cvoid}
        md == C_NULL && _throw_openssl_error("EVP_sha256")
        rc = @ccall libcrypto.EVP_DigestVerifyInit(
            ctx::Ptr{Cvoid}, C_NULL::Ptr{Ptr{Cvoid}}, md::Ptr{Cvoid}, C_NULL::Ptr{Cvoid}, pkey::Ptr{Cvoid})::Cint
        rc == 1 || _throw_openssl_error("EVP_DigestVerifyInit")
        # See the note in `rsa_sha256_sign`: `EVP_DigestVerifyUpdate` is a macro in OpenSSL 1.x.
        rc = @ccall libcrypto.EVP_DigestUpdate(ctx::Ptr{Cvoid}, data::Ptr{UInt8}, length(data)::Csize_t)::Cint
        rc == 1 || _throw_openssl_error("EVP_DigestUpdate (verify)")
        rc = @ccall libcrypto.EVP_DigestVerifyFinal(ctx::Ptr{Cvoid}, signature::Ptr{UInt8}, length(signature)::Csize_t)::Cint
        # 1 = valid, 0 = invalid signature, <0 = other error
        rc < 0 && _throw_openssl_error("EVP_DigestVerifyFinal")
        # An invalid signature leaves an error on the queue; do not let it leak.
        _clear_openssl_errors()
        return rc == 1
    finally
        ctx != C_NULL && @ccall libcrypto.EVP_MD_CTX_free(ctx::Ptr{Cvoid})::Cvoid
        @ccall libcrypto.EVP_PKEY_free(pkey::Ptr{Cvoid})::Cvoid
    end
end
