using GitHub, JSON, HTTP, MbedTLS, URIs
using Dates, Test, Base64
using GitHub: Branch, name
using GitHub.Checks

function get_gh_auth()::GitHub.Authorization
    auth = nothing
    names = [
        "MY_CUSTOM_GITHUB_TOKEN",
        "GITHUB_TOKEN",
    ]
    for name in names
        if auth === nothing
            if haskey(ENV, name)
                str = strip(ENV[name])
                if !isempty(str)
                    @info "Trying token from $name"
                    auth = authenticate(str)
                else
                    @warn "The $name environment variable is defined, but it is empty or consists only of whitespace"
                end
            end
        end
    end
    
    if auth === nothing
        @warn "Using anonymous GitHub access. If you get rate-limited, please set the MY_CUSTOM_GITHUB_TOKEN or GITHUB_TOKEN env var to an appropriate value."
        auth = GitHub.AnonymousAuth()
    end

    return auth
end

function check_is_gha_token(auth = get_gh_auth())
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
    return (testsuite_username, is_gha_token)
end

@testset "GitHub.jl" begin
    (testsuite_username, is_gha_token) = check_is_gha_token()
    @info "All is good. Exiting early to save CI time while debugging"
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
