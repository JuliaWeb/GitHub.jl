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
pubpem = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8IyF2xKWh/GQ10rAVKP7
G27z/wdSpc6pX1BRbB17FAo5gzHfH1eb/OjCFPJ1/VELVs1/muO+pBDbXi6Sb2+7
tPIkE0qXBsI6kfH16r3Tb5BiXCjTjBQGMpOCq/nohi5EsZ8YTyIKdwLkAeujsRVk
vKvW3i3rgj/znNpJq3GDDnW4kf10xU1BfE2dtKrpQyCJ8VjUoNVQ4f9CBX4fx4EE
+KK3JFyd9gPE5MbJ9cw0Y9FNtrkMODHW6W/N24ArvrbLThI0wKzbkKPP6sLTCPGp
VsCUjUz+VVZT9h1X1mo4TL8AssID8PtQqk+q6qWw4r3A6tCw6po2idhsRDSbaIWH
NQIDAQAB
-----END PUBLIC KEY-----
"""

# Fix iat, to make sure the payload is reproducible. The key can be given as a
# file path or as the PEM text.
auth = GitHub.JWTAuth(1234, keyfile; iat = DateTime("2016-9-15T14:00"))
auth2 = GitHub.JWTAuth(1234, keypem; iat = DateTime("2016-9-15T14:00"))
# The validity of this token can be checked with jwt.io. RS256 signatures are
# deterministic, so this must match byte for byte.
@test auth.JWT == correct_jwt
@test auth2.JWT == correct_jwt

@testset "RS256 signing" begin
    header, payload, sig = split(correct_jwt, '.')
    signing_input = string(header, '.', payload)
    sig_bytes = base64decode(string(sig, "=" ^ (4 - length(sig) % 4)) |> s -> replace(replace(s, '-' => '+'), '_' => '/'))
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
    @test_throws GitHub.OpenSSLError GitHub.rsa_sha256_sign(pubpem, signing_input)
    # Encrypted keys are rejected up front rather than prompting for a pass phrase
    @test_throws ArgumentError GitHub.rsa_sha256_sign("-----BEGIN ENCRYPTED PRIVATE KEY-----\nAAAA\n-----END ENCRYPTED PRIVATE KEY-----\n", signing_input)
    # Neither a PEM nor an existing file
    @test_throws ArgumentError GitHub.JWTAuth(1234, "definitely/not/a/file.pem")
end

@test_throws ArgumentError GitHub.OAuth2("ghp_\n")
@test_throws ArgumentError GitHub.JWTAuth("ghp_\n")
