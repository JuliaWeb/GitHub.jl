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
# Fix iat, to make sure the payload is reproducible
auth = GitHub.JWTAuth(1234, joinpath(dirname(@__FILE__), "not_a_real_key.pem");
    iat = DateTime("2016-9-15T14:00"))
key = MbedTLS.PKContext()
MbedTLS.parse_key!(key,
    read(joinpath(dirname(@__FILE__), "not_a_real_key.pem"), String))
auth = GitHub.JWTAuth(1234, joinpath(dirname(@__FILE__), "not_a_real_key.pem");
    iat = DateTime("2016-9-15T14:00"))
auth2 = GitHub.JWTAuth(1234, key; iat = DateTime("2016-9-15T14:00"))
# The validity of this token can be checked with jwt.io. This is just a smoke
# test to make sure things don't break.
@test auth.JWT == correct_jwt
@test auth2.JWT == correct_jwt

@test_throws ArgumentError GitHub.OAuth2("ghp_\n")
@test_throws ArgumentError GitHub.JWTAuth("ghp_\n")

@testset "uint64_hash tests" begin
    # Test that uint64_hash produces UInt64 values
    @test typeof(GitHub.uint64_hash("test")) == UInt64

    # Test that same input produces same output (deterministic)
    @test GitHub.uint64_hash("hello") == GitHub.uint64_hash("hello")

    # Test that different inputs produce different outputs
    @test GitHub.uint64_hash("hello") != GitHub.uint64_hash("world")

    # Test with empty string
    @test typeof(GitHub.uint64_hash("")) == UInt64

    # Test with special characters
    @test typeof(GitHub.uint64_hash("!@#\$%^&*()")) == UInt64
    @test GitHub.uint64_hash("test!") != GitHub.uint64_hash("test")
end

@testset "get_auth_hash tests" begin
    @testset "OAuth2 hashing" begin
        # Same token should produce same hash
        auth1 = GitHub.OAuth2("ghp_testtoken123456")
        auth2 = GitHub.OAuth2("ghp_testtoken123456")
        @test GitHub.get_auth_hash(auth1) == GitHub.get_auth_hash(auth2)
        @test typeof(GitHub.get_auth_hash(auth1)) == UInt64

        # Different tokens should produce different hashes
        auth3 = GitHub.OAuth2("ghp_differenttoken789")
        @test GitHub.get_auth_hash(auth1) != GitHub.get_auth_hash(auth3)
    end

    @testset "UsernamePassAuth hashing" begin
        # Same credentials should produce same hash
        auth1 = GitHub.UsernamePassAuth("user1", "pass1")
        auth2 = GitHub.UsernamePassAuth("user1", "pass1")
        @test GitHub.get_auth_hash(auth1) == GitHub.get_auth_hash(auth2)
        @test typeof(GitHub.get_auth_hash(auth1)) == UInt64

        # Different username should produce different hash
        auth3 = GitHub.UsernamePassAuth("user2", "pass1")
        @test GitHub.get_auth_hash(auth1) != GitHub.get_auth_hash(auth3)

        # Different password should produce different hash
        auth4 = GitHub.UsernamePassAuth("user1", "pass2")
        @test GitHub.get_auth_hash(auth1) != GitHub.get_auth_hash(auth4)
    end

    @testset "AnonymousAuth hashing" begin
        # AnonymousAuth should always return UInt64(0)
        auth1 = GitHub.AnonymousAuth()
        auth2 = GitHub.AnonymousAuth()
        @test GitHub.get_auth_hash(auth1) == UInt64(0)
        @test GitHub.get_auth_hash(auth2) == UInt64(0)
        @test GitHub.get_auth_hash(auth1) == GitHub.get_auth_hash(auth2)
    end

    @testset "JWTAuth hashing" begin
        # Same JWT should produce same hash
        auth1 = GitHub.JWTAuth(1234, joinpath(dirname(@__FILE__), "not_a_real_key.pem");
            iat = DateTime("2016-9-15T14:00"))
        auth2 = GitHub.JWTAuth(1234, joinpath(dirname(@__FILE__), "not_a_real_key.pem");
            iat = DateTime("2016-9-15T14:00"))
        @test GitHub.get_auth_hash(auth1) == GitHub.get_auth_hash(auth2)
        @test typeof(GitHub.get_auth_hash(auth1)) == UInt64

        # Different iat should produce different hash (different JWT)
        auth3 = GitHub.JWTAuth(1234, joinpath(dirname(@__FILE__), "not_a_real_key.pem");
            iat = DateTime("2016-9-15T14:01"))
        @test GitHub.get_auth_hash(auth1) != GitHub.get_auth_hash(auth3)
    end

    @testset "Different auth types produce different hashes" begin
        oauth = GitHub.OAuth2("ghp_samestring")
        anon = GitHub.AnonymousAuth()
        userpass = GitHub.UsernamePassAuth("user", "pass")

        # All should be different from each other
        @test GitHub.get_auth_hash(oauth) != GitHub.get_auth_hash(anon)
        @test GitHub.get_auth_hash(oauth) != GitHub.get_auth_hash(userpass)
        @test GitHub.get_auth_hash(anon) != GitHub.get_auth_hash(userpass)
    end
end
