########################
# Validation Functions #
########################

has_event_header(request::HttpCommon.Request) = haskey(request.headers, "X-GitHub-Event")
event_header(request::HttpCommon.Request) = request.headers["X-GitHub-Event"]

has_sig_header(request::HttpCommon.Request) = haskey(request.headers, "X-Hub-Signature")
sig_header(request::HttpCommon.Request) = request.headers["X-Hub-Signature"]

function is_valid_secret(request::HttpCommon.Request, secret::AbstractString)
    if has_sig_header(request)
        payload_string = UTF8String(request.data)
        secret_sha = "sha1="*MbedTLS.digest(MbedTLS.MD_SHA1, payload_string, secret)
        return sig_header(request) == secret_sha
    end
    return false
end

function is_valid_event(request::HttpCommon.Request, events)
    return (has_event_header(request) && in(EventName(request), events))
end

is_valid_repo(payload::Dict, repos) = in(payload["repository"]["full_name"], repos)

#################
# EventListener #
#################

"""
A `GitHub.EventListener` is a server that handles events sent from a GitHub repo (usually via a webhook). When a `GitHub.EventListener` receives an event, it performs some basic validation and wraps the event payload in a `GitHub.WebhookEvent` type (use the REPL's `help` mode for more info on `GitHub.WebhookEvent`). This `GitHub.WebhookEvent` is then fed to the server's `handle` function, which defines how the server responds to the event.

The `GitHub.EventListener` constructor takes in a handler function which should take in a `GitHub.WebhookEvent` and `GitHub.Authorization` and return an `HttpCommon.Response`. It also takes the following keyword arguments:

- `auth`: GitHub authorization (usually with repo-level permissions)
- `secret`: A string used to verify the event source. If the event is from a GitHub webhook, it's the webhook's secret
- `repos`: A collection of fully qualified names of whitelisted repostories. All repostories are whitelisted by default
- `events`: A collection of webhook event name strings that contains all whitelisted events. All events are whitelisted by default
- `forwards`: A collection of address strings to which any incoming requests should be forwarded (after being validated by the listener)

Here's an example that demonstrates how to construct and run a `GitHub.EventListener` that does some really basic benchmarking on every commit and PR:

    import GitHub

    # EventListener settings
    myauth = GitHub.OAuth2(ENV["GITHUB_AUTH_TOKEN"])
    mysecret = ENV["MY_SECRET"]
    myevents = ["pull_request", "push"]
    myrepos = ["owner1/repo1", "owner2/repo2"]
    myforwards = ["http://myforward1.com", "http://myforward2.com"]

    # Set up Status parameters
    pending_params = Dict(
        "state" => "pending",
        "context" => "Benchmarker",
        "description" => "Running benchmarks..."
    )

    success_params = Dict(
        "state" => "success",
        "context" => "Benchmarker",
        "description" => "Benchmarks complete!"
    )

    listener = GitHub.EventListener(auth = myauth,
                                    secret = mysecret,
                                    repos = myrepos,
                                    events = myevents,
                                    forwards = myforwards) do event, auth
        name, payload = event.name, event.payload

        if name == "pull_request" && payload["action"] == "closed"
            return HttpCommon.Response(200)
        end

        sha = GitHub.most_recent_commit(event)

        GitHub.create_status(event, sha; auth = auth, params = pending_params)

        # run_and_log_benchmarks isn't actually a defined function, but you get the point
        run_and_log_benchmarks("\$(sha)-benchmarks.csv")

        GitHub.create_status(event, sha; auth = auth, params = success_params)

        return HttpCommon.Response(200)
    end

    # Start the server on port 8000
    GitHub.run(listener, 8000)

"""
immutable EventListener
    server::HttpServer.Server
    function EventListener(handle; auth::Authorization = AnonymousAuth(),
                           secret = nothing, events = nothing,
                           repos = nothing, forwards = nothing)
        if !(isa(forwards, Void))
            forwards = map(HttpCommon.URI, forwards)
        end

        server = HttpServer.Server() do request, response
            try
                handle_event_request(request, handle; auth = auth,
                                     secret = secret, events = events,
                                     repos = repos, forwards = forwards)
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

function handle_event_request(request, handle;
                              auth::Authorization = AnonymousAuth(),
                              secret = nothing, events = nothing,
                              repos = nothing, forwards = nothing)
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

    event = event_from_payload!(event_header(request), payload)

    return handle(event, auth)
end

function Base.run(listener::EventListener, args...; kwargs...)
    return HttpServer.run(listener.server, args...; kwargs...)
end

###################
# CommentListener #
###################

const COMMENT_EVENTS = ["issue_comment",
                        "commit_comment",
                        "pull_request_review_comment"]

immutable CommentListener
    listener::EventListener
    function CommentListener(handle, trigger::AbstractString;
                             auth::Authorization = AnonymousAuth(),
                             secret = nothing,
                             repos = nothing,
                             forwards = nothing)
        listener = EventListener(auth=auth, secret=secret,
                                 events=COMMENT_EVENTS, repos=repos,
                                 forwards=forwards) do event, auth
            found, extracted = extract_trigger_string(event, auth, trigger)
            if found
                return handle(event, auth, extracted)
            else
                return HttpCommon.Response(204, extracted)
            end
        end
        return new(listener)
    end
end

function Base.run(listener::CommentListener, args...; kwargs...)
    return run(listener.listener, args...; kwargs...)
end

function extract_trigger_string(event::WebhookEvent,
                                auth::Authorization,
                                trigger::AbstractString)
    trigger_regex = Regex("\`$trigger\(.*?\)\`")

    # extract repo/owner info from event
    if isnull(event.repository)
        return (false, "event is missing repo information")
    end

    repo = get(event.repository)

    if isnull(repo.owner)
        return (false, "event repository is missing owner information")
    end

    owner = get(repo.owner)

    # extract comment from payload
    if !(haskey(event.payload, "comment"))
        return (false, "payload does not contain comment")
    end

    comment = event.payload["comment"]

    # check if comment is from collaborator
    if !(iscollaborator(owner, repo, comment["user"]["login"]; auth = auth))
        return (false, "commenter is not collaborator")
    end

    # check for trigger phrase
    body = get(comment, "body", "")

    trigger_match = match(trigger_regex, body)

    if trigger_match == nothing
        return (false, "trigger phrase not found")
    end

    return (true, first(trigger_match.captures))
end
