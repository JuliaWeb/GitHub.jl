using GitHub, GitHub.name
using Base.Test

# The below tests are network-dependent, and actually make calls to GitHub's
# API. They're all read-only, meaning none of them require authentication.

testuser = Owner("julia-github-test-bot")
julweb = Owner("JuliaWeb", true)
ghjl = Repo("JuliaWeb/GitHub.jl")
testcommit = Commit("3a90e7d64d6184b877f800570155c502b1119c15")

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

##########
# Owners #
##########

@test name(owner(testuser; auth = auth)) == name(testuser)
@test name(owner(julweb; auth = auth)) == name(julweb)
@test hasghobj("JuliaWeb", orgs("jrevels"; auth = auth))
@test hasghobj("jrevels", followers(testuser; auth = auth))
@test hasghobj("jrevels", following(testuser; auth = auth))
@test hasghobj(ghjl, repos(julweb; auth = auth))

################
# Repositories #
################

@test name(repo(ghjl; auth = auth)) == name(ghjl)
@test length(forks(ghjl; auth = auth)) > 0
@test hasghobj("jrevels", map(x->x["contributor"], contributors(ghjl; auth = auth)))
@test stats(ghjl, "contributors"; auth = auth).status == 200

@test name(commit(ghjl, testcommit; auth = auth)) == name(testcommit)
@test hasghobj(testcommit, commits(ghjl; auth = auth))
@test file(ghjl, "README.md"; auth = auth) == readme(ghjl; auth = auth)
@test hasghobj("src/GitHub.jl", directory(ghjl, "src"; auth = auth))
@test !(isempty(statuses(ghjl, testcommit; auth = auth)))

# These require `auth` to have push-access (it's currently a read-only token)
# @test hasghobj("jrevels", collaborators(ghjl; auth = auth))
# @test iscollaborator(ghjl, "jrevels"; auth = auth)

##########
# Issues #
##########

state_param = Dict("state" => "all")

@test get(pull_request(ghjl, 37; auth = auth).title) == "Fix dep warnings"
@test hasghobj(37, pull_requests(ghjl; auth = auth, params = state_param))
@test get(issue(ghjl, 40; auth = auth).title) == "Needs test"
@test hasghobj(40, issues(ghjl; auth = auth, params = state_param))
@test !(isempty(issue_comments(ghjl, 40; auth = auth)))

############
# Activity #
############
@test length(stargazers(ghjl; auth = auth)) > 10 # every package should fail tests if it's not popular enough :p
@test hasghobj(ghjl, starred(testuser; auth = auth))
@test hasghobj(testuser, watchers(ghjl; auth = auth))
@test hasghobj(ghjl, watched(testuser; auth = auth))
