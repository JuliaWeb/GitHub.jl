########################
# Validation Functions #
########################

has_event_header(request::HttpCommon.Request) = haskey(request.headers, "X-GitHub-Event")
event_header(request::HttpCommon.Request) = request.headers["X-GitHub-Event"]

has_sig_header(request::HttpCommon.Request) = haskey(request.headers, "X-Hub-Signature")
sig_header(request::HttpCommon.Request) = request.headers["X-Hub-Signature"]

function has_valid_secret(request::HttpCommon.Request, secret)
    if has_sig_header(request)
        secret_sha = "sha1="*bytes2hex(MbedTLS.digest(MbedTLS.MD_SHA1, request.data, secret))
        return sig_header(request) == secret_sha
    end
    return false
end

function is_valid_event(request::HttpCommon.Request, events)
    return (has_event_header(request) && in(event_header(request), events))
end

function from_valid_repo(event, repos)
    return (name(event.repository) == "" || in(name(event.repository), repos))
end

#################
# EventListener #
#################

immutable EventListener
    server::HttpServer.Server
    function EventListener(handle; auth::Authorization = AnonymousAuth(),
                           secret = nothing, events = nothing,
                           repos = nothing, forwards = nothing)
        if !(isa(forwards, Void))
            forwards = map(HttpCommon.URI, forwards)
        end

        if !(isa(repos, Void))
            repos = map(name, repos)
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
    if !(isa(secret, Void)) && !(has_valid_secret(request, secret))
        return HttpCommon.Response(400, "invalid signature")
    end

    if !(isa(events, Void)) && !(is_valid_event(request, events))
        return HttpCommon.Response(400, "invalid event")
    end

    event = event_from_payload!(event_header(request), Requests.json(request))

    if !(isa(repos, Void)) && !(from_valid_repo(event, repos))
        return HttpCommon.Response(400, "invalid repo")
    end

    if !(isa(forwards, Void))
        for address in forwards
            Requests.post(address, request)
        end
    end

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
                             check_collab::Bool = true,
                             secret = nothing,
                             repos = nothing,
                             forwards = nothing)
        listener = EventListener(auth=auth, secret=secret,
                                 events=COMMENT_EVENTS, repos=repos,
                                 forwards=forwards) do event, auth
            found, extracted = extract_trigger_string(event, auth, trigger, check_collab)
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
                                trigger::AbstractString,
                                check_collab::Bool)
    trigger_regex = Regex("\`$trigger\(.*?\)\`")

    # extract repo/owner info from event
    repo = event.repository

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
    if (check_collab &&
        !(iscollaborator(owner, repo, comment["user"]["login"]; auth = auth)))
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
