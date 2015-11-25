using GitHub, JLD
using Base.Test

event_request = JLD.load(joinpath(Pkg.dir("GitHub"), "test", "commit_comment.jld"), "r")
event_json = Requests.json(event_request)
event = GitHub.event_from_payload!("commit_comment", event_json)

################
# WebhookEvent #
################

@test get(get(event.repository).name) == "BenchmarkTrackers.jl"
@test get(get(event.sender).login) == "jrevels"
@test most_recent_commit_sha(event) == "32d35f285777b077d8b6a2521309d1ab646d2379"

#################
# EventListener #
#################

@test !(GitHub.is_valid_secret(event_request, "wrong"))
@test GitHub.is_valid_secret(event_request, "secret")
@test !(GitHub.is_valid_event(event_request, ["wrong"]))
@test GitHub.is_valid_event(event_request, ["commit_comment"])
@test GitHub.handle_event_request(event_request, (args...) -> true,
                                  secret = "secret",
                                  events = ["commit_comment"],
                                  repos = ["JuliaCI/BenchmarkTrackers.jl"])

###################
# CommentListener #
###################

trigger_results = GitHub.extract_trigger_string(event, GitHub.AnonymousAuth(), "RunBenchmarks", false)

@test trigger_results == (true,"(\"binary\", \"unary\")")
