using GitHub, GitHub.name
using Base.Test

# The below tests are network-dependent, and actually make calls to GitHub's
# API. They're all read-only, meaning none of them require authentication.

testuser = Owner("julia-github-test-bot")
julweb = Owner("JuliaWeb", true)
ghjl = Repo("JuliaWeb/GitHub.jl")
testcommit = Commit("3a90e7d64d6184b877f800570155c502b1119c15")
testuser_pubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVDBxFza4BmQTCTFeTyK"*
    "3xT+T98dmiMWXC2lM/esw3MCRHg7cynLWr/jUgjs72DO2nqlCTKI88yd2gcbW5/pBP6NVumc"*
    "pM7eJzZJ3TKKwdGUD49nahncg5imHZUQbCqtQbAYEj+uFfqa9QNm6NkZdAdPdB6dJG2+QEuk"*
    "rIGWKsmihP7vGzRLdebGwng2aNUfdAyVwq5Af4g5qfyRT9MtOXXM/7tDAVfC/g4QjkQ52giG"*
    "3FRqehMHOfl4iw9cYggJ3owr+T/RhwBHhE9G+sIaq4cEjRxogf65xzJfRtxxM2RBYDM9GMyX"*
    "6s2dFghew6MMc2x7OJM30W+OedhtZuk3Xp"

hasghobj(obj, items) = any(x -> name(x) == name(obj), items)

# This token has public, read-only access, and is required so that our
# tests don't get rate-limited. The only way a malicious party could do harm
# with this token is if they used it to abuse the rate limit associated with
# the token (not too big of a deal). The token is hard-coded in an obsfucated
# manner in an attempt to thwart token-stealing crawlers.
auth = authenticate(string(circshift(["bcc", "3fc", "03a", "33e",
                                      "c09", "363", "5f1", "bd3",
                                      "fc6", "77b", '5', "9cf",
                                      "868", "033"], 3)...))

@test rate_limit(; auth = auth)["rate"]["limit"] == 5000

@testset "Owners" begin
    # test GitHub.owner
    @test name(owner(testuser; auth = auth)) == name(testuser)
    @test name(owner(julweb; auth = auth)) == name(julweb)

    # test GitHub.orgs
    @test hasghobj("JuliaWeb", first(orgs("jrevels"; auth = auth)))

    # test GitHub.followers, GitHub.following
    @test hasghobj("jrevels", first(followers(testuser; auth = auth)))
    @test hasghobj("jrevels", first(following(testuser; auth = auth)))

    # test GitHub.repos
    @test hasghobj(ghjl, first(repos(julweb; auth = auth)))

    # test pubkey retrieval
    @test first(values(GitHub.pubkeys(testuser; auth = auth)[1])) == testuser_pubkey

    # test membership queries
    @test GitHub.check_membership(julweb, testuser; auth = auth)
    @test !GitHub.check_membership("JuliaLang", testuser; auth = auth, public_only=true)
end

@testset "Repositories" begin
    # test GitHub.repo
    @test name(repo(ghjl; auth = auth)) == name(ghjl)

    # test GitHub.forks
    @test length(first(forks(ghjl; auth = auth))) > 0

    # test GitHub.contributors
    @test hasghobj("jrevels", map(x->x["contributor"], first(contributors(ghjl; auth = auth))))

    # test GitHub.stats
    @test stats(ghjl, "contributors"; auth = auth).status < 300

    # test GitHub.branch, GitHub.branches
    @test name(branch(ghjl, "master"; auth = auth)) == "master"
    @test hasghobj("master", first(branches(ghjl; auth = auth)))

    # test GitHub.commit, GitHub.commits
    @test name(commit(ghjl, testcommit; auth = auth)) == name(testcommit)
    @test hasghobj(testcommit, first(commits(ghjl; auth = auth)))

    # test GitHub.file, GitHub.directory, GitHub.readme, GitHub.permalink
    readme_file = file(ghjl, "README.md"; auth = auth)
    src_dir = first(directory(ghjl, "src"; auth = auth))
    owners_dir = src_dir[findfirst(c -> get(c.path) == "src/owners", src_dir)]
    test_sha = "eab14e1ab7b4de848ef6390101b6d40b489d5d08"
    readme_permalink = string(permalink(readme_file, test_sha))
    owners_permalink = string(permalink(owners_dir, test_sha))
    @test readme_permalink == "https://github.com/JuliaWeb/GitHub.jl/blob/$(test_sha)/README.md"
    @test owners_permalink == "https://github.com/JuliaWeb/GitHub.jl/tree/$(test_sha)/src/owners"
    @test readme_file == readme(ghjl; auth = auth)
    @test hasghobj("src/GitHub.jl", src_dir)

    # test GitHub.status, GitHub.statuses
    @test get(status(ghjl, testcommit; auth = auth).sha) == name(testcommit)
    @test !(isempty(first(statuses(ghjl, testcommit; auth = auth))))

    # test GitHub.comment, GitHub.comments
    @test name(comment(ghjl, 154431956; auth = auth)) == 154431956
    @test !(isempty(first(comments(ghjl, 40; auth = auth))))

    # These require `auth` to have push-access (it's currently a read-only token)
    # @test hasghobj("jrevels", first(collaborators(ghjl; auth = auth)))
    # @test iscollaborator(ghjl, "jrevels"; auth = auth)
end

@testset "Issues" begin
    state_param = Dict("state" => "all")

    # test GitHub.pull_request, GitHub.pull_requests
    @test get(pull_request(ghjl, 37; auth = auth).title) == "Fix dep warnings"
    @test hasghobj(37, first(pull_requests(ghjl; auth = auth, params = state_param)))

    # test GitHub.issue, GitHub.issues
    @test get(issue(ghjl, 40; auth = auth).title) == "Needs test"
    @test hasghobj(40, first(issues(ghjl; auth = auth, params = state_param)))
end

@testset "Gists" begin
    kc_gists, page_data = gists("KristofferC"; page_limit=1, params=Dict("per_page" => 5), auth = auth)
    @test typeof(kc_gists) == Vector{Gist}
    @test length(kc_gists) != 0
    @test get(get(kc_gists[1].owner).login) == "KristofferC"

    gist_obj = gist("0cb70f50a28d79905aae907e12cbe58e"; auth = auth)
    @test length(get(gist_obj.files)) == 2
    @test get(gist_obj.files)["file1.jl"]["content"] == "Hello World!"
end

@testset "Activity" begin
    # test GitHub.stargazers, GitHub.starred
    @test length(first(stargazers(ghjl; auth = auth))) > 10 # every package should fail tests if it's not popular enough :p
    @test hasghobj(ghjl, first(starred(testuser; auth = auth)))

    # test GitHub.watched, GitHub.watched
    @test hasghobj(testuser, first(watchers(ghjl; auth = auth)))
    @test hasghobj(ghjl, first(watched(testuser; auth = auth)))
end

@testset "Apps" begin
    @test get(app(4123).name) == "femtocleaner"
    @test get(app("femtocleaner").name) == "femtocleaner"
end
