#####################
# WebhookEvent Type #
#####################

type WebhookEvent
    kind::GitHubString
    payload::Dict
    repository::Repo
    sender::Owner
end

function event_from_payload!(kind, data::Dict)
    if haskey(data, "repository")
        repository = Repo(data["repository"])
    elseif kind == "membership"
        repository = Repo("")
    else
        error("event payload is missing repository field")
    end

    if haskey(data, "sender")
        sender = Owner(data["sender"])
    else
        error("event payload is missing sender")
    end

    return WebhookEvent(kind, data, repository, sender)
end

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

    return handle(event)
end

function Base.run(listener::EventListener, args...; kwargs...)
    return HttpServer.run(listener.server, args...; kwargs...)
end

###################
# CommentListener #
###################

const COMMENT_EVENTS = ["commit_comment",
                        "pull_request",
                        "pull_request_review_comment",
                        "issues",
                        "issue_comment"]

immutable CommentListener
    listener::EventListener
    function CommentListener(handle, trigger::Regex;
                             auth::Authorization = AnonymousAuth(),
                             check_collab::Bool = true,
                             secret = nothing,
                             repos = nothing,
                             forwards = nothing)
        listener = EventListener(auth=auth, secret=secret,
                                 events=COMMENT_EVENTS, repos=repos,
                                 forwards=forwards) do event
            return handle_comment(handle, event, auth, trigger, check_collab)
        end
        return new(listener)
    end
end

function Base.run(listener::CommentListener, args...; kwargs...)
    return run(listener.listener, args...; kwargs...)
end

function handle_comment(handle, event::WebhookEvent, auth::Authorization,
                        trigger::Regex, check_collab::Bool)
    kind, payload = event.kind, event.payload

    if (kind == "pull_request" || kind == "issues") && payload["action"] == "opened"
        body_container = kind == "issues" ? payload["issue"] : payload["pull_request"]
    elseif haskey(payload, "comment")
        body_container = payload["comment"]
    else
        return HttpCommon.Response(204, "payload does not contain comment")
    end

    if check_collab
        repo = event.repository
        user = body_container["user"]["login"]
        if !(iscollaborator(repo, user; auth = auth))
            return HttpCommon.Response(204, "commenter is not collaborator")
        end
    end

    trigger_match = match(trigger, body_container["body"])

    if trigger_match == nothing
        return HttpCommon.Response(204, "trigger match not found")
    end

    return handle(event, trigger_match)
end
