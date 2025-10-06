# The below tests are network-dependent, and actually make calls to GitHub's
# API. They're all read-only, meaning none of them require authentication.

# testuser = Owner("julia-github-test-bot")
# testuser2 = Owner("julia-github-test-bot2")
julweb = Owner("JuliaWeb", true)
ghjl = Repo("JuliaWeb/GitHub.jl")
testcommit = Commit("627128970bbf09d27c526cb66a17891c389ab914")

# This is a public SSH key registered for the julia-github-test-bot2 user.
# If this key breaks, please ask anyone with access to
# subscriptions+githubtestbot@julialang.org to re-add or replace it.
testuser2_sshkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkj86sSo36bkgv+gKp"*
    "8sdvrDUzWrswx5rIBXxZblIZyflam0YU1jcma8wtij+mm7JCSZm0Z9jaLYX7TRKhYHOPlX"*
    "RScbi5l+Hi1jAK744XX6fvuOyWctBsUy5vc2L7PkRxIh9pFm7aOEPQF863eYhuuuB8lcRq"*
    "yKKs55NbUWDZJTkj5qBgV5INSwdwJyWu/gof0KxZxG5ovQ+NZvlillgjf36mEniijahbKj"*
    "IVlgZ9dmTbJKTJFfOn8Q+JmNQiNLNJIb/MDJ/el/0Ai7C7Sg2xwyXvVHfc1c0DOMIf1J1W"*
    "uU/LatiEUqhQiy31k4O9oGM4rtZKpWFfZl2t6ScBPcqwn48NnXlG/BaxpZRL+Q/St7yCtk"*
    "KY6Gr/ZvRxQwE/1WAiBCBwEpSMMyhUzpfkWESsb1QX4dcPY7vJB9eA0t+8iaHlgMJel+aG"*
    "K7KkjfdvZbAa9cvE5Yw3jQBgbp6goBsZjTxktPhsJWQCG0P62VGBic1gRKQlusM8M8q2uI"*
    "d4PR8="

hasghobj(obj, items) = any(x -> name(x) == name(obj), items)

auth = nothing

names = [
    "MY_CUSTOM_GITHUB_TOKEN",
    "GITHUB_TOKEN",
]
for name in names
    global auth
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

# is_gha_token is true if we're using the GITHUB_TOKEN made available automatically in GitHub Actions
# false otherwise
#
# This try-catch is a crude heuristic.
# Ideally there would be an actual API we could hit to determine this.
(testsuite_username, is_gha_token) = try
    w = GitHub.whoami(; auth=auth)
    @info "Information for the test user being used in the test suite" w w.login
    (w.login, false)
catch ex
    @info "Looks like this is the GITHUB_TOKEN from GitHub Actions"
    ("github-actions[bot]", true)
end

@test rate_limit(; auth = auth)["rate"]["limit"] > 0

testuser = Owner(testsuite_username)

@testset "Owners" begin
    # test GitHub.owner
    @test name(owner(testuser; auth = auth)) == name(testuser)
    @test name(owner(julweb; auth = auth)) == name(julweb)

    # test GitHub.orgs
    @test hasghobj("JuliaWeb", first(orgs("jrevels"; auth = auth)))
    members, _ = GitHub.members(Owner("JuliaLang"); auth=auth)
    @test length(members) > 1

    # test GitHub.followers, GitHub.following
    @test_skip hasghobj("jrevels", first(followers(testuser; auth = auth))) # TODO FIXME: Fix these tests. https://github.com/JuliaWeb/GitHub.jl/issues/236
    @test_skip hasghobj("jrevels", first(following(testuser; auth = auth))) # TODO FIXME: Fix these tests. https://github.com/JuliaWeb/GitHub.jl/issues/236

    # test GitHub.repos
    @test hasghobj(ghjl, first(repos(julweb; auth = auth)))

    # test sshkey/gpgkey retrieval
    # Test commented out because testuser2 seems to have been deleted or the key removed
    # @test GitHub.sshkeys(testuser2; auth = auth)[1][1]["key"] == testuser2_sshkey
    # @test startswith(GitHub.gpgkeys("JuliaTagBot"; auth = auth)[1][1]["raw_key"],
    #                  "-----BEGIN PGP PUBLIC KEY BLOCK-----")

    # test membership queries
    if is_gha_token
        # The `@test ex skip=is_gha_token` syntax requires Julia 1.7+, so we can't use it here.
        @info "Skipping check_membership() test because is_gha_token is true" is_gha_token
        @test_skip GitHub.check_membership(julweb, testuser; auth = auth)
    else
        @test GitHub.check_membership(julweb, testuser; auth = auth)
    end
    
    @test !GitHub.check_membership("JuliaLang", testuser; auth = auth, public_only=true)

    @test GitHub.isorg(julweb)
    @test !GitHub.isorg(testuser)
end

@testset "Repositories" begin
    # test GitHub.repo
    repo_obj = repo(ghjl; auth = auth)
    @test name(repo_obj) == name(ghjl)
    @test typeof(repo_obj.license) == License
    @test name(repo_obj.license) == "MIT"

    # test GitHub.forks
    @test length(first(forks(ghjl; auth = auth))) > 0

    # test GitHub.contributors
    @test hasghobj("jrevels", map(x->x["contributor"], first(contributors(ghjl; auth = auth))))

    # test GitHub.stats
    @test stats(ghjl, "contributors"; auth = auth).status < 300

    # test GitHub.branch, GitHub.branches
    @test name(branch(ghjl, "master"; auth = auth)) == "master"
    @test hasghobj("master", first(branches(ghjl; auth = auth)))

    # test GitHub.compare
    # check if the latest commit is a merge commit
    latest_commit = GitHub.branch(ghjl, "master"; auth=auth).commit
    is_latest_commit_merge = length(latest_commit.parents) > 1
    if is_latest_commit_merge
        @test compare(ghjl, "master", "master~"; auth = auth).behind_by >= 1
        let comparison = compare(ghjl, "master~", "master"; auth = auth)
            @test comparison.ahead_by >= 1
            @test length(comparison.commits) >= 1
        end
    else
        @test compare(ghjl, "master", "master~"; auth = auth).behind_by == 1
        let comparison = compare(ghjl, "master~", "master"; auth = auth)
            @test comparison.ahead_by == 1
            @test length(comparison.commits) == 1
        end
    end

    # test GitHub.file, GitHub.directory, GitHub.readme, GitHub.permalink
    readme_file = file(ghjl, "README.md"; auth = auth)
    src_dir = first(directory(ghjl, "src"; auth = auth))
    owners_dir = src_dir[findfirst(c -> c.path == "src/owners", src_dir)]
    test_sha = "eab14e1ab7b4de848ef6390101b6d40b489d5d08"
    readme_permalink = string(permalink(readme_file, test_sha))
    owners_permalink = string(permalink(owners_dir, test_sha))
    @test readme_permalink == "https://github.com/JuliaWeb/GitHub.jl/blob/$(test_sha)/README.md"
    @test owners_permalink == "https://github.com/JuliaWeb/GitHub.jl/tree/$(test_sha)/src/owners"
    @test readme_file == readme(ghjl; auth = auth)
    @test occursin("GitHub.jl", String(readme_file))
    @test hasghobj("src/GitHub.jl", src_dir)

    # test GitHub.status, GitHub.statuses
    # FIXME: for some reason, the GitHub API reports empty statuses on the GitHub.jl repo
    let ghjl = Repo("JuliaLang/julia"), testcommit = Commit("3200219b1f7e2681ece9e4b99bda48586fab8a93")
        @test status(ghjl, testcommit; auth = auth).sha == name(testcommit)
        # The statuses API seems to be broken / not documented correctly. Ref: https://github.com/orgs/community/discussions/55455
        # @test !(isempty(first(statuses(ghjl, testcommit; auth = auth))))
    end

    # test GitHub.comment, GitHub.comments
    @test name(comment(ghjl, 154431956; auth = auth)) == 154431956
    @test !(isempty(first(comments(ghjl, 40; auth = auth))))

    # These require `auth` to have push-access (it's currently a read-only token)
    # @test hasghobj("jrevels", first(collaborators(ghjl; auth = auth)))
    # @test iscollaborator(ghjl, "jrevels"; auth = auth)
end

@testset "Commits" begin
    # of a repo
    @test name(commit(ghjl, testcommit; auth = auth)) == name(testcommit)
    @test hasghobj(testcommit, first(commits(ghjl; auth = auth)))

    # of a pull request
    let pr = pull_request(ghjl, 37; auth = auth)
        commit_vec, page_data = commits(pr; auth = auth)
        @test commit_vec isa Vector{Commit}
        @test length(commit_vec) == 1
    end
    let
        commit_vec, page_data = commits(ghjl, 37; auth = auth)
        @test commit_vec isa Vector{Commit}
        @test length(commit_vec) == 1
    end
end

@testset "Issues" begin
    state_param = Dict("state" => "all")

    # test GitHub.pull_request, GitHub.pull_requests
    let pr = pull_request(ghjl, 37; auth = auth)
        @test pr.title == "Fix dep warnings"
        @test length(pr.labels) == 1
        @test pr.labels[1].name == "enhancement"
    end
    @test hasghobj(37, first(pull_requests(ghjl; auth = auth, params = state_param)))

    # test GitHub.issue, GitHub.issues
    @test issue(ghjl, 40; auth = auth).title == "Needs test"
    @test hasghobj(40, first(issues(ghjl; auth = auth, params = state_param)))
end

@testset "Gists" begin
    # skip=is_gha_token
    if is_gha_token
        @info "Skipping gists tests because is_gha_token is true" is_gha_token
        @test_skip false
    else
        kc_gists, page_data = gists("KristofferC"; page_limit=1, params=Dict("per_page" => 5), auth = auth)
        @test typeof(kc_gists) == Vector{Gist}
        @test length(kc_gists) != 0
        @test kc_gists[1].owner.login == "KristofferC"
    
        gist_obj = gist("0cb70f50a28d79905aae907e12cbe58e"; auth = auth)
        @test length(gist_obj.files) == 2
        @test gist_obj.files["file1.jl"]["content"] == "Hello World!"
    end
end

@testset "Reviews" begin
    pr = pull_request(ghjl, 59; auth = auth)
    review = first(reviews(ghjl, pr; auth=auth)[1])

    @test review.state == "CHANGES_REQUESTED"
end

@testset "Activity" begin
    # test GitHub.stargazers, GitHub.starred
    @test length(first(stargazers(ghjl; auth = auth))) > 10 # every package should fail tests if it's not popular enough :p
    @test_skip hasghobj(ghjl, first(starred(testuser; auth = auth))) # TODO FIXME: Fix these tests. https://github.com/JuliaWeb/GitHub.jl/issues/237

    # test GitHub.watched, GitHub.watched
    @test_skip hasghobj(testuser, first(watchers(ghjl; auth = auth))) # TODO FIXME: Fix these tests. https://github.com/JuliaWeb/GitHub.jl/issues/237
    @test_skip hasghobj(ghjl, first(watched(testuser; auth = auth))) # TODO FIXME: Fix these tests. https://github.com/JuliaWeb/GitHub.jl/issues/237
end

testbot_key =
      "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBcFB0d1ZhWWVRVUtWcDFv"*
      "cDMzUnhxWVhUM0dPTFZmOHIvN25SejZkVDVMVzBoUUFXCjZyVEN2NzV0RDdueU5wTGtrdmZGcng2QzlaTlg4"*
      "NTFZSEhMZ3hQNHhFbTcrb2lBajlqNjNwRkxybDNqUEd6RDAKQmVVNkcyVitpNGc5c00rMnpvR3RlbFpQaW4w"*
      "RHhhZi9TSThCL2ZxcmJ4SVVVMjN3T0hDZDU3L0Q2WUVQWFFOagpWTzczb0xXb0ltNTkxc3VLNDZOcTdMNkhq"*
      "SW85M0R6eWNWUExyRDNiK0xTSXlZQXMzTnhPTXNuNTZ5S0JLaVp1CktHMldnVjJOWlBOUXlZYVdCQWtKZzB6"*
      "cFBDUVdXcStZYkh4QS8rRHIrNnRsSXFnS3QyTWFlNGJKZ1FtTEgxSzkKNjRnR0RuK04zQTlmQ04rRjlLUndD"*
      "a3dsek1JeCtGSFhuMnh6NHdJREFRQUJBb0lCQUZBVXFDTTZ2ZWJKYmlETQpXQlRaemE0T2dwYXdUdHJRUUVn"*
      "aHB5RFhSSlo0U0laaVU3MWJQa2lhSXhBR0h2YTBlSFNLQmcrSmpPR3N3bjFDCmU1bGJmWlRCR1lxc0M3Y2dT"*
      "TFJuSHZhSk5VZlI0UjErdG9RQ0R5RnJNM0NCRWdpMzJqRUVxdkw5NENBRnJJWU4KbEpGZ3NRUFozOHJMQ01p"*
      "eVRXN240dzJ4ZkdQamRLcitlbTc4R0syUU1ad0l5WllQTG90V2dnc0QyY1lQV1BsdQpyQ2VRSmt2blVKMnhS"*
      "RTdnWUQ5YkUzdWFUN0xiUFhYZldwYW81aVZFdjFROCtJZjFON2wveTlkODBhY1BiUDNHCkFZY0NqeWprN1NV"*
      "bEhKYVNlYXNzbFBpT1FiOS9xNUh3aVljQTZRbnZCSlkvTjdVWGJQVXVOZEl0U2NmdUZQQUwKKyt3T0RtRUNn"*
      "WUVBMWJHZHlnT0NOZzNWUEVlNjRuSzlvTklGV043ZlE2SngvbUZIb3NUUHV3d3BMaFlLb3htMgpFMTl3Mzlh"*
      "TDROYWJ3TWZnVGIyRDJBbXVpUTJkaXRQNHRjc1cxOUZXS09peWhWdXgrSFl2eWt4TTZwRFVZa2Q1CitEY1lS"*
      "NFd1bVpjcUZSRlc3YmN4SXA2eWdseHgwNHhuMmg5U3Bnb0dwRDBFY2ZQOEFpbFl1NUVDZ1lFQXhhVUgKdEhW"*
      "cXk1WnRPRElEbkUwclJtQzdlUjlzdGR3eUZwdlJ0RWcvenBJZEIwVHUyVFFzZ3djRGc3N0ZLRUdvVEpJcQpr"*
      "WFFBdXJVOWRpUXkyVTVZT2J6R3lvSG9JTFpTc0FhV2JjOU10amVNaFdGVFhSNnNrY2loS0NSd0Z3UTNscyty"*
      "CnRtUkVXTGtDUm0rOVBJVjJxalg2SG9kNktWT2NkV0FEYldnR3RqTUNnWUJEL0JnSkZ3aXNEY2FUUVBiUjZG"*
      "TXcKQU9FMm51RkU4VDkzQUpmN3pzV1A2cFNIVnZmWFgreXZTU1B0OHFIWnpDME5MZ25NY2NpcVNKcEFmQlpz"*
      "L25jWAp6eDdiVm53azA3TkgvaDRtditNQVp6bnBQbDV6VGU0ZDY5bExsOW91ZndzaVhMdmRNUFR1NExKR0N3"*
      "Y2ptSDNKCnhVRlVGY2g3SS9ad0VvRlFacnNXSVFLQmdRQ2pFWjVoemQ3blNwMmlsK0ZTdkhqUUFFK3RoN2Z4"*
      "OUZOL1ErQ3AKbGxMTzVNNytpR2xvM0JzOW9EUE9KMEFVRHRnRkZUUDUvblA3bUQyMWsvaEFRdHVZQjZFY3hF"*
      "SDVlM1NOdDJHMgpDQ3VLekJvc2tqaHR4RGt0cnhNSVE4Z1h0V3NJQ3gvcHhLQi9jMlhsSjV4Q3F2dFZSR094"*
      "ZktYV0l4NGIyYlA2Ck9MSVE4UUtCZ0Z5cERKdXczYjFZVEpqbmI0UTZQR0FaUzNtVDZ1SVVrbGtmWENuNWo4"*
      "SUNFMXpZNVl1RDRpbE4KR3RkWHlqeitiMVg2UEZnVFhpdzQxU2xaUXMrVzhZUXVQSHA2QWFsV3VBN1l6cFNp"*
      "eWd3eFlaaWFIODlGWUxuagpxdm1lMDFIeUtIdnRQOE95YmI0UGsvZ3V0aXlaV0U0RW1JVWZEZ2I4RlY4VU5z"*
      "MW1IcklTCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg=="

@testset "Apps" begin
    @test app(4123; auth=auth).name == "femtocleaner"
    @test app("femtocleaner"; auth=auth).name == "femtocleaner"

    key = MbedTLS.PKContext()
    MbedTLS.parse_key!(key, base64decode(testbot_key))
    jwt = GitHub.JWTAuth(4484, key)
    @test app(; auth=jwt).name == "juliawebtestbot"

    @test length(installations(jwt)[1]) == 1
end

@testset "Git Data" begin
    github_jl = Repo("JuliaWeb/GitHub.jl")

    g = gitcommit(github_jl, "0d9f04ce4be061d3c2b12644316a232c8f889b44"; auth=auth)
    @test g.tree["sha"] == "e22fee36cb13d9a1850b242f79938458221a5d2e"

    t = tree(github_jl, g.tree["sha"]; auth=auth)
    for entry in t.tree
        if entry["path"] == "README.md"
            @test entry["sha"] == "95c8d1aa2a7b1e6d672e15b67e0df4abbe57dcbe"
            @test entry["type"] == "blob"

            b = blob(github_jl, entry["sha"]; auth=auth)
            @test occursin("GitHub.jl", String(b))

            break
        end
    end
end

@testset "Tags and References" begin
    # All tags in this repo are lightweight tags which are not covered by the API
    # Maybe test in the future when we have a use case
    github_jl = Repo("JuliaWeb/GitHub.jl")
    ref = reference(github_jl, "heads/master"; auth=auth)
    @test ref.object["type"] == "commit"

    # Tag API
    reponame = "JuliaGPU/Adapt.jl"
    ## lightweight tag
    version = "v0.1.0"
    exptag = tag(reponame, version; auth=auth)
    @test isa(exptag, Tag)
    @test exptag.object["type"] == "commit"
    ## lightweight tag pointing to an annotated tag (should return the annotated tag)
    version = "v3.4.0"
    exptag = tag(reponame, version; auth=auth)
    @test isa(exptag, Tag)
    @test exptag.object["type"] == "commit"
end

@testset "URI constructions" begin
    public_gh = GitHub.DEFAULT_API
    enterprise_gh = GitHub.GitHubWebAPI(URIs.URI("https://git.company.com/api/v3"))
    @test  GitHub.api_uri(public_gh, "/rate_limit") == URIs.URI("https://api.github.com/rate_limit")
    @test  GitHub.api_uri(enterprise_gh, "/rate_limit") == URIs.URI("https://git.company.com/api/v3/rate_limit")
end

@testset "Licenses" begin
    # test GitHub.licenses
    licenses_obj, page_data = licenses(; page_limit = 1, auth = auth)
    @test typeof(licenses_obj) == Vector{License}
    @test length(licenses_obj) != 0

    # test GitHub.license
    license_obj = license("MIT"; auth = auth)
    @test typeof(license_obj) == License
    @test name(license_obj) == "MIT"
    @test license_obj.name == "MIT License"
    @test startswith(license_obj.body, "MIT License\n\nCopyright (c) [year] [fullname]\n\nPermission is hereby granted,")

    # test GitHub.repo_license
    repo_license_obj = repo_license(ghjl; auth = auth)
    @test typeof(repo_license_obj) == Content
    @test name(repo_license_obj.license) == "MIT"
    @test name(repo_license_obj) == "LICENSE.md"
    @test repo_license_obj.path == "LICENSE.md"
    @test repo_license_obj.typ == "file"
end

@testset "Topics" begin
    # test GitHub.topics
    topics_obj, page_data = topics(ghjl; auth = auth)
    @test typeof(topics_obj) == Vector{String}
    @test length(topics_obj) == 0

    # also test on a repository that _does_ have topics
    topics_obj, page_data = topics("JuliaLang/julia"; auth = auth)
    @test length(topics_obj) > 0
end

@testset "Prevent Path Traversal" begin
    @test_throws ArgumentError GitHub.api_uri(GitHub.DEFAULT_API, "/repos/foo/../bar")
    @test_throws ArgumentError GitHub.api_uri(GitHub.DEFAULT_API, "/repos/foo/../bar")
    @test string(GitHub.api_uri(GitHub.DEFAULT_API, "/repos/foo/bar")) == "https://api.github.com/repos/foo/bar"
end
