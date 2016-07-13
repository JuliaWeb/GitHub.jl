using GitHub
using JLD
using Base.Test

event_request = JLD.load(joinpath(dirname(@__FILE__), "commit_comment.jld"), "request")

event_json = Requests.json(event_request)

event = GitHub.event_from_payload!("commit_comment", event_json)

################
# WebhookEvent #
################

@test get(event.repository.name) == "BenchmarkTrackers.jl"
@test get(event.sender.login) == "jrevels"

#################
# EventListener #
#################

@test !(GitHub.has_valid_secret(event_request, "wrong"))
@test GitHub.has_valid_secret(event_request, "secret")
@test !(GitHub.is_valid_event(event_request, ["wrong"]))
@test GitHub.is_valid_event(event_request, ["commit_comment"])
@test !(GitHub.from_valid_repo(event, ["JuliaWeb/GitHub.jl"]))
@test GitHub.from_valid_repo(event, ["JuliaCI/BenchmarkTrackers.jl"])
@test GitHub.handle_event_request(event_request, x -> true,
                                  secret = "secret",
                                  events = ["commit_comment"],
                                  repos = ["JuliaCI/BenchmarkTrackers.jl"])

@test begin
    listener = EventListener(x -> true;
                             secret = "secret",
                             repos = [Repo("JuliaCI/BenchmarkTrackers.jl"), "JuliaWeb/GitHub.jl"],
                             events = ["commit_comment"],
                             forwards = ["http://bob.com", HttpCommon.URI("http://jim.org")])
    r = listener.server.http.handle(HttpCommon.Request(),HttpCommon.Response())
    r.status == 400
end

###################
# CommentListener #
###################

result = GitHub.handle_comment((e, m) -> m, event, GitHub.AnonymousAuth(), r"`RunBenchmarks\(.*?\)`", false)

@test result.match == "`RunBenchmarks(\"binary\", \"unary\")`"

@test begin
    listener = CommentListener((x, y) -> true, r"trigger";
                               secret = "secret",
                               repos = [Repo("JuliaCI/BenchmarkTrackers.jl"), "JuliaWeb/GitHub.jl"],
                               forwards = ["http://bob.com", HttpCommon.URI("http://jim.org")],
                               check_collab = false)
    r = listener.listener.server.http.handle(HttpCommon.Request(), HttpCommon.Response())
    r.status == 400
end
