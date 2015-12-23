using GitHub, JLD
using Base.Test

event_request = JLD.load(joinpath(Pkg.dir("GitHub"), "test", "commit_comment.jld"), "r")
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

trigger_results = GitHub.extract_trigger_string(event, GitHub.AnonymousAuth(), "RunBenchmarks", false)

@test trigger_results == (true,"(\"binary\", \"unary\")")

@test begin
    listener = CommentListener((x, y) -> true, "trigger";
                               secret = "secret",
                               repos = [Repo("JuliaCI/BenchmarkTrackers.jl"), "JuliaWeb/GitHub.jl"],
                               forwards = ["http://bob.com", HttpCommon.URI("http://jim.org")],
                               check_collab = false)

    r = listener.listener.server.http.handle(HttpCommon.Request(),HttpCommon.Response())
    r.status == 400
end
