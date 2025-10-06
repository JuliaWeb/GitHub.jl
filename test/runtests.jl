using GitHub, JSON, HTTP, MbedTLS, URIs
using Dates, Test, Base64
using GitHub: Branch, name
using GitHub.Checks

@testset "GitHub.jl" begin

    # We add some `sleep()`s throughout the test suite, to reduce the chance of getting rate-limited.

    sleep(2)
    include("ghtype_tests.jl")

    sleep(2)
    include("event_tests.jl")

    sleep(2)
    include("read_only_api_tests.jl")

    sleep(2)
    include("auth_tests.jl")
    
    @testset "SSH keygen" begin
        pubkey, privkey = GitHub.genkeys(keycomment="GitHub.jl")
        @test endswith(pubkey, "GitHub.jl")
        @test isa(privkey, String)
    end

end
