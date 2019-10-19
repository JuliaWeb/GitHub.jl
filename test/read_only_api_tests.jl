# The below tests are network-dependent, and actually make calls to GitHub's
# API. They're all read-only, meaning none of them require authentication.

testuser = Owner("julia-github-test-bot")
julweb = Owner("JuliaWeb", true)
ghjl = Repo("JuliaWeb/GitHub.jl")
testcommit = Commit("3a90e7d64d6184b877f800570155c502b1119c15")
testuser_sshkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVDBxFza4BmQTCTFeTyK"*
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

    # test sshkey/gpgkey retrieval
    @test_broken GitHub.sshkeys(testuser; auth = auth)[1][1]["key"] == testuser_sshkey
    @test startswith(GitHub.gpgkeys("JuliaTagBot"; auth = auth)[1][1]["raw_key"],
                     "-----BEGIN PGP PUBLIC KEY BLOCK-----")

    # test membership queries
    @test GitHub.check_membership(julweb, testuser; auth = auth)
    @test !GitHub.check_membership("JuliaLang", testuser; auth = auth, public_only=true)

    @test GitHub.isorg(julweb)
    @test !GitHub.isorg(testuser)
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
    owners_dir = src_dir[findfirst(c -> c.path == "src/owners", src_dir)]
    test_sha = "eab14e1ab7b4de848ef6390101b6d40b489d5d08"
    readme_permalink = string(permalink(readme_file, test_sha))
    owners_permalink = string(permalink(owners_dir, test_sha))
    @test readme_permalink == "https://github.com/JuliaWeb/GitHub.jl/blob/$(test_sha)/README.md"
    @test owners_permalink == "https://github.com/JuliaWeb/GitHub.jl/tree/$(test_sha)/src/owners"
    @test readme_file == readme(ghjl; auth = auth)
    @test hasghobj("src/GitHub.jl", src_dir)

    # test GitHub.status, GitHub.statuses
    @test status(ghjl, testcommit; auth = auth).sha == name(testcommit)
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
    @test pull_request(ghjl, 37; auth = auth).title == "Fix dep warnings"
    @test hasghobj(37, first(pull_requests(ghjl; auth = auth, params = state_param)))

    # test GitHub.issue, GitHub.issues
    @test issue(ghjl, 40; auth = auth).title == "Needs test"
    @test hasghobj(40, first(issues(ghjl; auth = auth, params = state_param)))
end

@testset "Gists" begin
    kc_gists, page_data = gists("KristofferC"; page_limit=1, params=Dict("per_page" => 5), auth = auth)
    @test typeof(kc_gists) == Vector{Gist}
    @test length(kc_gists) != 0
    @test kc_gists[1].owner.login == "KristofferC"

    gist_obj = gist("0cb70f50a28d79905aae907e12cbe58e"; auth = auth)
    @test length(gist_obj.files) == 2
    @test gist_obj.files["file1.jl"]["content"] == "Hello World!"
end

@testset "Reviews" begin
    pr = pull_request(ghjl, 59; auth = auth)
    review = first(reviews(ghjl, pr; auth=auth)[1])

    @test review.state == "CHANGES_REQUESTED"
end

@testset "Activity" begin
    # test GitHub.stargazers, GitHub.starred
    @test length(first(stargazers(ghjl; auth = auth))) > 10 # every package should fail tests if it's not popular enough :p
    @test hasghobj(ghjl, first(starred(testuser; auth = auth)))

    # test GitHub.watched, GitHub.watched
    @test hasghobj(testuser, first(watchers(ghjl; auth = auth)))
    @test hasghobj(ghjl, first(watched(testuser; auth = auth)))
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
            @test occursin("GitHub.jl", String(base64decode(replace(b.content,"\n" => ""))))

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
    reponame = "QuantEcon/Expectations.jl"
    version = "v1.0.1"
    exptag = tag(reponame, version; auth=auth)
    @test isa(exptag, Tag)
end
