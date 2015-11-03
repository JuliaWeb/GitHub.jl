#################
# EventListener #
#################

"""
A `GitHub.EventListener` is a server that handles events sent from a GitHub repo (usually via a webhook). When a `GitHub.EventListener` receives an event, it performs some basic validation and wraps the event payload in a `GitHub.Event` type (use the REPL's `help` mode for more info on `GitHub.Event`). This `GitHub.Event` is then fed to the server's `handle` function, which defines how the server responds to the event.

The `GitHub.EventListener` constructor takes in a handler function which should take in a `GitHub.Event` and `GitHub.Authorization` and return an `HttpCommon.Response`. It also takes the following keyword arguments:

- `auth`: GitHub authorization (usually with repo-level permissions)
- `secret`: A string used to verify the event source. If the event is from a GitHub webhook, it's the webhook's secret
- `repos`: A collection of fully qualified names of whitelisted repostories. All repostories are whitelisted by default
- `events`: A `GitHub.EventName` collection that contains all whitelisted events. All events are whitelisted by default
- `forwards`: A collection of address strings to which any incoming requests should be forwarded (after being validated by the listener)

Here's an example that demonstrates how to construct and run a `GitHub.EventListener` that does some really basic benchmarking on every commit and PR (the function `run_and_log_benchmarks` used below isn't actually defined, but you get the point):

    import GitHub

    myauth = GitHub.OAuth2(ENV["GITHUB_AUTH_TOKEN"])
    mysecret = ENV["MY_SECRET"]
    myevents = [GitHub.PullRequestEvent, GitHub.PushEvent]
    myrepos = ["owner1/repo1", "owner2/repo2"]
    myforwards = ["http://myforward1.com", "http://myforward2.com"]

    listener = GitHub.EventListener(auth = myauth,
                                    secret = mysecret,
                                    repos = myrepos,
                                    events = myevents,
                                    forwards = myforwards) do event, auth
        name, payload = GitHub.name(event), GitHub.payload(event)

        if name == GitHub.PullRequestEvent && payload["action"] == "closed"
            return HttpCommon.Response(200)
        end

        sha = GitHub.most_recent_commit(event)

        GitHub.post_status(event, sha, GitHub.PENDING;
                           auth = auth, context = "Benchmarker",
                           description = "Running benchmarks...")

        log = "\$(sha)-benchmarks.csv"

        print("Running and logging benchmarks to \$(log)...")
        run_and_log_benchmarks(log)
        println("done.")

        GitHub.post_status(event, sha, GitHub.SUCCESS,
                           auth = auth, context = "Benchmarker",
                           description = "Benchmarks complete!")

        return HttpCommon.Response(200)
    end

    # Start the server on port 8000
    GitHub.run(listener, 8000)

"""
immutable EventListener
    server::HttpServer.Server
    function EventListener(handle;
                           auth::Authorization = AnonymousAuth(),
                           secret = nothing,
                           events = nothing,
                           repos = nothing,
                           forwards = nothing)
        if !(isa(forwards, Void))
            forwards = map(HttpCommon.URI, forwards)
        end

        server = HttpServer.Server() do request, response
            try
                if !(isa(secret, Void)) && !(is_valid_secret(request, secret))
                    return HttpCommon.Response(400, "invalid signature")
                end

                if !(isa(events, Void)) && !(is_valid_event(request, events))
                    return HttpCommon.Response(400, "invalid event")
                end

                payload = Requests.json(request)

                if !(isa(repos, Void)) && !(is_valid_repo(payload, repos))
                    return HttpCommon.Response(400, "invalid repo")
                end

                if !(isa(forwards, Void))
                    for address in forwards
                        Requests.post(address,
                                      UTF8String(request.data),
                                      headers=request.headers)
                    end
                end

                event = Event(request, payload)

                return handle(event, auth)
            catch err
                println("SERVER ERROR: $err")
                return HttpCommon.Response(500)
            end
        end

        server.http.events["listen"] = port -> begin
            println("Listening for GitHub events sent to $port;")
            println("Whitelisted events: $(isa(events, Void) ? "All" : events)")
            println("Whitelisted repos: $(isa(repos, Void) ? "All" : repos)")
        end

        return new(server)
    end
end

function Base.run(listener::EventListener, args...; kwargs...)
    return HttpServer.run(listener.server, args...; kwargs...)
end

########################
# Validation Functions #
########################

has_sig_header(request::HttpCommon.Request) = haskey(request.headers, "X-Hub-Signature")
sig_header(request::HttpCommon.Request) = request.headers["X-Hub-Signature"]

function is_valid_secret(request::HttpCommon.Request, secret::AbstractString)
    if has_sig_header(request)
        payload_string = UTF8String(request.data)
        secret_sha = "sha1="*Nettle.hexdigest("sha1", secret, payload_string)
        return sig_header(request) == secret_sha
    end
    return false
end

function is_valid_event(request::HttpCommon.Request, events)
    return (has_event_header(request) && in(EventName(request), events))
end

is_valid_repo(payload::Dict, repos) = in(payload["repository"]["full_name"], repos)
