using GitHub, JSON, HTTP, MbedTLS, URIs
using Dates, Test, Base64
using GitHub: Branch, name
using GitHub.Checks

include("ghtype_tests.jl")
include("event_tests.jl")
include("read_only_api_tests.jl")
include("auth_tests.jl")

@testset "SSH keygen" begin
    pubkey, privkey = GitHub.genkeys(keycomment="GitHub.jl")
    @test endswith(pubkey, "GitHub.jl")
    @test isa(privkey, String)
end
