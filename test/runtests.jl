using GitHub, JSON, HTTP, MbedTLS, URIs
using Dates, Test, Base64
using GitHub: Branch, name
using GitHub.Checks

function check_is_gha_token()
    (testsuite_username, is_gha_token) = try
        w = GitHub.whoami(; auth)
        @info "Information for the test user being used in the test suite" w w.login
        (w.login, false)
    catch ex1
        # @info "This might be the GITHUB_TOKEN from GitHub Actions. We'll double-check"
        a = GitHub.app(; auth)
        @info "" a
        exit(1)
    end
    return (; testsuite_username, is_gha_token)
end

@testset "GitHub.jl" begin
    (; testsuite_username, is_gha_token) = check_is_gha_token()
    exit(1)

    include("ghtype_tests.jl")
    include("event_tests.jl")
    include("read_only_api_tests.jl")
    include("auth_tests.jl")
    include("retries.jl")
  
    @testset "SSH keygen" begin
        pubkey, privkey = GitHub.genkeys(keycomment="GitHub.jl")
        @test endswith(pubkey, "GitHub.jl")
        @test isa(privkey, String)
    end

end
