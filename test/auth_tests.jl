correct_jwt = replace("""
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.
eyJleHAiOjE0NzM5NDgwNjAsImlhdCI6MTQ3Mzk0ODAwMCwiaXNzIjoxMjM0fQ.
uDZWWptpvEy4Dv1h_jHcqqROzs2HpE_XMcSfNWhpCuLNwnVPWUVoTYqiCPbNdO7
PgsuTMhtuF4PQN0bJdz7_Bnn0UqmHZ-P1ktFeMBT7IvfEBolIVLMTa2LJQC6UG7
_qCoY2kjLdriWiLFHznJvG6jfPHK-iX9VIolNjkiM9e4DG9Aq60UnZ_df40wZXd
696sRpgCakvIV3mQTmRv9IfOLVF9eRRD4yVvwTtYNGOqewpQqkPnm6K3ctYlQIX
kwKMynp6R-CgbwRedA4n0WAvy1o14TyZZ-QAChQUcS-OKb0ZM4z-fbG5ZSpWP7f
wsQxsZgWFIz6hodiw_q45bHYsLw
""",'\n' => "")
keyfile = joinpath(dirname(@__FILE__), "not_a_real_key.pem")
keypem = read(keyfile, String)
# Public half of not_a_real_key.pem (`openssl pkey -in not_a_real_key.pem -pubout`)
pubpem = read(joinpath(dirname(@__FILE__), "pubkey.pem"), String)

# Fix iat, to make sure the payload is reproducible. The key can be given as a
# file path or as the PEM text.
auth = GitHub.JWTAuth(1234, keyfile; iat = DateTime("2016-9-15T14:00"))
auth2 = GitHub.JWTAuth(1234, keypem; iat = DateTime("2016-9-15T14:00"))
# The validity of this token can be checked with jwt.io. RS256 signatures are
# deterministic, so this must match byte for byte.
@test auth.JWT == correct_jwt
@test auth2.JWT == correct_jwt

@testset "JWTAuth key forms" begin
    iat = DateTime("2016-9-15T14:00")
    # PEM bytes
    @test GitHub.JWTAuth(1234, Vector{UInt8}(codeunits(keypem)); iat = iat).JWT == correct_jwt
    # PKCS#1 DER (the base64 body of the "BEGIN RSA PRIVATE KEY" PEM), as bytes and as a file
    der = base64decode(join(filter(l -> !startswith(l, "-----"), split(strip(keypem), '\n'))))
    @test GitHub.JWTAuth(1234, der; iat = iat).JWT == correct_jwt
    mktemp() do path, io
        write(io, der); close(io)
        @test GitHub.JWTAuth(1234, path; iat = iat).JWT == correct_jwt
    end
    # PKCS#8 DER, as `openssl pkey -in not_a_real_key.pem -outform DER` emits:
    # SEQUENCE { INTEGER 0, SEQUENCE { OID rsaEncryption, NULL }, OCTET STRING { pkcs1 } }
    der_len(n) = n < 0x80 ? UInt8[n] : (b = reverse(digits(UInt8, n; base = 256)); UInt8[0x80 | length(b); b])
    der_tlv(tag, content) = UInt8[tag; der_len(length(content)); content]
    rsa_oid = der_tlv(0x06, UInt8[0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01])
    pkcs8 = der_tlv(0x30, [der_tlv(0x02, UInt8[0x00]); der_tlv(0x30, [rsa_oid; der_tlv(0x05, UInt8[])]); der_tlv(0x04, der)])
    @test GitHub.JWTAuth(1234, pkcs8; iat = iat).JWT == correct_jwt
    @test_throws GitHub.OpenSSLError GitHub.JWTAuth(1234, UInt8[0x30, 0x03, 0x02, 0x01, 0x00])
    # A parsed key can be reused
    key = GitHub.RSAPrivateKey(keypem)
    @test GitHub.JWTAuth(1234, key; iat = iat).JWT == correct_jwt
    @test GitHub.JWTAuth(1234, key; iat = iat).JWT == correct_jwt
    @test !occursin("PRIVATE", sprint(show, key))
    # A key file path is accepted, as by `JWTAuth`
    @test GitHub.JWTAuth(1234, GitHub.RSAPrivateKey(keyfile); iat = iat).JWT == correct_jwt
    # Signing with key bytes works, and an unsupported key type is a MethodError
    # (not a stack overflow from the forwarding methods)
    @test GitHub.rsa_sha256_sign(der, "abc") == GitHub.rsa_sha256_sign(keypem, "abc")
    @test_throws MethodError GitHub.rsa_sha256_sign(1, "abc")
    @test_throws MethodError GitHub.rsa_sha256_sign(1, UInt8[1])
    # A freed key is rejected rather than handed to OpenSSL
    freed = GitHub.RSAPrivateKey(keypem)
    finalize(freed)
    @test_throws ArgumentError GitHub.rsa_sha256_sign(freed, "abc")
    # Raw pointers cannot be wrapped (two owners would double-free the key)
    @test_throws MethodError GitHub.RSAPrivateKey(key.ptr)
    # A deep copy shares the OpenSSL object by reference count, so freeing one copy
    # neither frees the other nor double-frees the key
    orig = GitHub.RSAPrivateKey(keypem)
    copied = deepcopy(orig)
    finalize(orig)
    @test GitHub.JWTAuth(1234, copied; iat = iat).JWT == correct_jwt
    finalize(copied)
    @test_throws ArgumentError GitHub.rsa_sha256_sign(copied, "abc")
    @test deepcopy(copied).ptr == C_NULL
    # Encrypted DER (PKCS#8 EncryptedPrivateKeyInfo) gets the same clear error as PEM
    # SEQUENCE { SEQUENCE { NULL } ... }, with short- and long-form outer lengths
    @test_throws ArgumentError GitHub.RSAPrivateKey(UInt8[0x30, 0x04, 0x30, 0x02, 0x05, 0x00])
    @test_throws ArgumentError GitHub.RSAPrivateKey(UInt8[0x30, 0x81, 0x04, 0x30, 0x02, 0x05, 0x00])
end

@testset "RS256 signing" begin
    header, payload, sig = split(correct_jwt, '.')
    signing_input = string(header, '.', payload)
    sig_bytes = base64decode(replace(replace(string(sig, "=" ^ mod(-length(sig), 4)), '-' => '+'), '_' => '/'))
    @test GitHub.rsa_sha256_sign(keypem, signing_input) == sig_bytes
    @test length(sig_bytes) == 256  # 2048-bit key

    # Verifies with the public key and with the private key's public half
    @test GitHub.rsa_sha256_verify(pubpem, signing_input, sig_bytes)
    @test GitHub.rsa_sha256_verify(keypem, signing_input, sig_bytes)

    # Tampered input or signature does not verify (and does not throw)
    @test !GitHub.rsa_sha256_verify(pubpem, signing_input * " ", sig_bytes)
    bad_sig = copy(sig_bytes); bad_sig[1] ⊻= 0x01
    @test !GitHub.rsa_sha256_verify(pubpem, signing_input, bad_sig)

    # Error handling
    @test_throws GitHub.OpenSSLError GitHub.rsa_sha256_sign("-----BEGIN RSA PRIVATE KEY-----\nnot a key\n-----END RSA PRIVATE KEY-----\n", signing_input)
    # A public key is named as such rather than surfacing OpenSSL's bare "unsupported"
    @test_throws ArgumentError GitHub.rsa_sha256_sign(pubpem, signing_input)
    @test_throws ArgumentError GitHub.rsa_sha256_sign(Vector{UInt8}(codeunits(pubpem)), signing_input)
    # Encrypted keys are rejected up front rather than prompting for a pass phrase
    @test_throws ArgumentError GitHub.rsa_sha256_sign("-----BEGIN ENCRYPTED PRIVATE KEY-----\nAAAA\n-----END ENCRYPTED PRIVATE KEY-----\n", signing_input)
    for proctype in ("Proc-Type: 4,ENCRYPTED", "Proc-Type:4,ENCRYPTED", "Proc-Type: 4, ENCRYPTED")
        legacy = "-----BEGIN RSA PRIVATE KEY-----\n$proctype\nDEK-Info: AES-128-CBC,00\n\nAAAA\n-----END RSA PRIVATE KEY-----\n"
        @test_throws ArgumentError GitHub.rsa_sha256_sign(legacy, signing_input)
    end
    # Byte-vector views are accepted, not just `Vector{UInt8}`
    @test GitHub.rsa_sha256_sign(keypem, codeunits(signing_input)) == sig_bytes
    @test GitHub.rsa_sha256_verify(pubpem, codeunits(signing_input), view(sig_bytes, :))
    # Non-RSA keys are rejected instead of producing a non-RS256 signature
    # Throwaway P-256 key generated for this test (`openssl ecparam -name prime256v1 -genkey -noout`)
    ecpem = """
    -----BEGIN EC PRIVATE KEY-----
    MHcCAQEEIHyAiu+3axTFLU/eEgV+pWBfYvFuPV7ltDIBH/cBmO/ioAoGCCqGSM49
    AwEHoUQDQgAEch1tFqcAjXDF6VhSKYRON+hWWbiVR/45Os4f/wgQgQSGwJk8cWdC
    cdvvMOQ5ANacCZUSmejGy/hW9yLSXe2Jaw==
    -----END EC PRIVATE KEY-----
    """
    @test_throws ArgumentError GitHub.rsa_sha256_sign(ecpem, signing_input)
    @test_throws ArgumentError GitHub.rsa_sha256_verify(ecpem, signing_input, sig_bytes)
    # RSA-PSS keys are restricted to PSS padding and would yield a PS256 signature
    # Throwaway key generated for this test (`openssl genpkey -algorithm RSA-PSS -pkeyopt rsa_keygen_bits:1024`)
    psspem = """
    -----BEGIN PRIVATE KEY-----
    MIICdQIBADALBgkqhkiG9w0BAQoEggJhMIICXQIBAAKBgQC0lqGYJYjxVoHUjjHu
    RjvAZdgxE391yDvAYzJiYWw+ZsTqYzrKbKDKlrzrogwhzNBECudmdYzeuH6YJ54a
    tLe/dyPrXa2NMnJqSDiVfeznbMeMOlNw37fBn28Whi2QiZk6R0vBGNsyR5SfgrCb
    P+6wGFGfUn9A+o6HRPgWy4LldwIDAQABAoGAPnyku7W5NfD+CaOOSWmKAV/8N7cM
    cp/vdPmeFIarYshCuOvPCv4dgRw5kLtIwWVSZ0jymvRv4x0pyNJklc8UiRoNhERM
    9r2K4w2RzRT3sQhh/wn56/Obzz4Z3qsgh+bfaw2IRT8Ux9svSisTYHt6WsKgmMmt
    BkE2zwx7cxjKNnkCQQDY6oAnEKLLKNQPi7SH7MAjcGSRro95uCr5c6aIa0acdkYo
    xySKUJHjM/B9MmIXMs2eTBEGAAW+UNxglKhbkO6zAkEA1SB6VNHTmvYWO7DslHSF
    KivYfVFDjNAEt4M/E3/OxTcSRcnn33MCvfQ5/vB2HCMkZ4mh015TJ2l6Ib0DnktQ
    LQJAGnw3fY2YcvnfOq6yMk6D/0+/19HajuAfzymB0fJXQs9mLaBzI7hGt9klqgO2
    2mJHnOZoxbTG/r/cyKYeEGAX5QJBAIP2lyhbv50skHmnQ+Vr/GQvP93gamYPC0yh
    nHWzZlEgl1TU/piRuvno9dwQAeHMNKdTRfr9ZZl6qt+nDE2ALoUCQQC9ewaDmKz3
    jf5lkmeA6IFJK1pk9ZzJxrXNJAGcNXhqSfMDXVuufNcQwgp+Fa/FjaJobBdTAtcm
    NiCQPBAHB2QT
    -----END PRIVATE KEY-----
    """
    @test_throws ArgumentError GitHub.rsa_sha256_sign(psspem, signing_input)
    # Neither a PEM nor an existing file
    @test_throws ArgumentError GitHub.JWTAuth(1234, "definitely/not/a/file.pem")
    # Strings that cannot be a path (e.g. a base64-encoded key) get the same error,
    # not an `IOError` from `stat`
    @test_throws ArgumentError GitHub.JWTAuth(1234, base64encode(keypem))
    @test_throws ArgumentError GitHub.JWTAuth(1234, "a"^300)
    @test_throws ArgumentError GitHub.JWTAuth(1234, "a\0b")
end

@test_throws ArgumentError GitHub.OAuth2("ghp_\n")
@test_throws ArgumentError GitHub.JWTAuth("ghp_\n")
