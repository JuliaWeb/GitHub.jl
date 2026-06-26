using Sockets

include("commit_comment.jl")
event_request = create_event()
event_json = JSON.parse(GitHub.http_payload(event_request, String))
event = GitHub.event_from_payload!("commit_comment", event_json)

@testset "WebhookEvent" begin
    @test event.repository.name == "BenchmarkTrackers.jl"
    @test event.sender.login == "jrevels"
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
                                forwards = ["http://bob.com", URIs.URI("http://jim.org")])
        r = listener.handle_request(HTTP.Request())
        r.status == 400
    end
end

@testset "CommentListener" begin
    result = GitHub.handle_comment((e, m) -> m, event, GitHub.AnonymousAuth(), r"`RunBenchmarks\(.*?\)`", false, false)
    @test result.match == "`RunBenchmarks(\"binary\", \"unary\")`"
    @test begin
        listener = CommentListener((x, y) -> true, r"trigger";
                                secret = "secret",
                                repos = [Repo("JuliaCI/BenchmarkTrackers.jl"), "JuliaWeb/GitHub.jl"],
                                forwards = ["http://bob.com", URIs.URI("http://jim.org")],
                                check_collab = false)
        r = listener.listener.handle_request(HTTP.Request())
        r.status == 400
    end
end

@testset "HTTPClientServer" begin
    auth = GitHub.JWTAuth(4123, "not_a_real_key.pem")

    function test_handler(event::WebhookEvent, phrase::RegexMatch)
       return HTTP.Response((phrase.match == "RunBenchmarks") ? 200 : 500)
    end
    listener = GitHub.CommentListener(test_handler, r"RunBenchmarks"; check_collab=false, auth=auth, secret=nothing)
    host = IPv4("127.0.0.1")

    if GitHub._HTTP_V1
        # HTTP 1.x: serve on a pre-bound socket and stop by closing it.
        port, sock = Sockets.listenany(host, 8001)

        srvrtask = @async GitHub.run(listener, sock, host, Int(port))

        server_started = false
        while !server_started
            try
                close(connect(host, port))
                server_started = true
            catch
                yield()
            end
        end

        resp = HTTP.request("POST", "http://$host:$port", event_request.headers, event_request.body)
        @test resp.status == 200

        try
            close(sock)
            wait(srvrtask)
        catch
        end
    else
        # HTTP 2.x: drive `GitHub.run` itself (it must accept an `IPAddr` host and
        # start an HTTP 2.x server). `run` blocks, so launch it from a task; if it
        # errors (e.g. a bad serve call) the task dies and `server_started` stays
        # false, failing the test below.
        port = 8002
        srvrtask = @async GitHub.run(listener, host, port)

        server_started = false
        t0 = time()
        while !server_started && time() - t0 < 10
            try
                close(connect(host, port))
                server_started = true
            catch
                sleep(0.05)
            end
        end
        @test server_started

        resp = HTTP.request("POST", "http://$host:$port", event_request.headers, event_request.body)
        @test resp.status == 200
        # `run`'s blocking server task is left to be torn down at process exit.
    end
end
