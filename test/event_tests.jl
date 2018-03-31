include("commit_comment.jl")
event_request = create_event()
event_json = JSON.parse(HTTP.payload(event_request, String))
event = GitHub.event_from_payload!("commit_comment", event_json)

@testset "WebhookEvent" begin
    @test get(event.repository.name) == "BenchmarkTrackers.jl"
    @test get(event.sender.login) == "jrevels"
end # testset

@testset "EventListener" begin
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
                                forwards = ["http://bob.com", HTTP.URI("http://jim.org")])
        r = listener.handle_request(HTTP.Request())
        r.status == 400
    end
end

@testset "CommentListener" begin
    result = GitHub.handle_comment((e, m) -> m, event, GitHub.AnonymousAuth(), r"`RunBenchmarks\(.*?\)`", false)
    @test result.match == "`RunBenchmarks(\"binary\", \"unary\")`"
    @test begin
        listener = CommentListener((x, y) -> true, r"trigger";
                                secret = "secret",
                                repos = [Repo("JuliaCI/BenchmarkTrackers.jl"), "JuliaWeb/GitHub.jl"],
                                forwards = ["http://bob.com", HTTP.URI("http://jim.org")],
                                check_collab = false)
        r = listener.listener.handle_request(HTTP.Request())
        r.status == 400
    end
end
