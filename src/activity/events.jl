#####################
# WebhookEvent Type #
#####################

mutable struct WebhookEvent
    kind::String
    payload::Dict
    repository::Repo
    sender::Owner
end

function event_from_payload!(kind, data::Dict)
    if haskey(data, "repository")
        repository = Repo(data["repository"])
    elseif kind == "membership" ||
           kind == "integration_installation" ||
           kind == "installation" ||
           kind == "installation_repositories" ||
           kind == "integration_installation_repositories"
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

has_event_header(request::HTTP.Request) = haskey(HTTP.headers(request), "X-Github-Event")
event_header(request::HTTP.Request) = HTTP.headers(request)["X-Github-Event"]

has_sig_header(request::HTTP.Request) = haskey(HTTP.headers(request), "X-Hub-Signature")
sig_header(request::HTTP.Request) = HTTP.headers(request)["X-Hub-Signature"]

function has_valid_secret(request::HTTP.Request, secret)
    if has_sig_header(request)
        secret_sha = "sha1="*bytes2hex(MbedTLS.digest(MbedTLS.MD_SHA1, String(request), secret))
        return sig_header(request) == secret_sha
    end
    return false
end

function is_valid_event(request::HTTP.Request, events)
    return (has_event_header(request) && in(event_header(request), events))
end

function from_valid_repo(event, repos)
    return (name(event.repository) == "" || in(name(event.repository), repos))
end

#################
# EventListener #
#################

struct EventListener
    server::HTTP.Server
    repos
    events
    function EventListener(handle; auth::Authorization = AnonymousAuth(),
                           secret = nothing, events = nothing,
                           repos = nothing, forwards = nothing)
        if !(isa(forwards, Void))
            forwards = map(HTTP.URI, forwards)
        end

        if !(isa(repos, Void))
            repos = map(name, repos)
        end

        server = HTTP.Server() do request, response
            try
                handle_event_request(request, handle; auth = auth,
                                     secret = secret, events = events,
                                     repos = repos, forwards = forwards)
            catch err
                bt = catch_backtrace()
                print(STDERR, "SERVER ERROR: ")
                Base.showerror(STDERR, err, bt)
                return HTTP.Response(500)
            end
        end

        return new(server, repos, events)
    end
end

function handle_event_request(request, handle;
                              auth::Authorization = AnonymousAuth(),
                              secret = nothing, events = nothing,
                              repos = nothing, forwards = nothing)
    if !(isa(secret, Void)) && !(has_valid_secret(request, secret))
        return HTTP.Response(400, "invalid signature")
    end

    if !(isa(events, Void)) && !(is_valid_event(request, events))
        return HTTP.Response(204, "event ignored")
    end

    event = event_from_payload!(event_header(request), JSON.parse(String(request)))

    if !(isa(repos, Void)) && !(from_valid_repo(event, repos))
        return HTTP.Response(400, "invalid repo")
    end

    if !(isa(forwards, Void))
        for address in forwards
            HTTP.post(address, request)
        end
    end

    retval = handle(event)
    if retval isa HttpCommon.Response
        Base.depwarn("event handlers should return an `HTTP.Response` instead of an `HttpCommon.Response`,
                 making a best effort to convert to an `HTTP.Response`", :handle_event_request)
        retval = HTTP.Response(; status = retval.status, headers = convert(Dict{String, String}, retval.headers),
                                 body = HTTP.FIFOBuffer(retval.data))
    end
    return retval
end

function Base.run(listener, args...; host = nothing, port = nothing, kwargs...)
    if host != nothing || port != nothing
        Base.depwarn("The `host` and `port` keywords are deprecated, use `run(listener, host, port, args...; kwargs...)`", :run)
    end
    run(listener, host, port, args...; kwargs...)
end

function Base.run(listener::EventListener, host::HTTP.IPAddr, port::Int, args...; kwargs...)
    println("Listening for GitHub events sent to $port;")
    println("Whitelisted events: $(isa(listener.events, Void) ? "All" : listener.events)")
    println("Whitelisted repos: $(isa(listener.repos, Void) ? "All" : listener.repos)")
    return HTTP.serve(listener.server, host, port, args...; kwargs...)
end

###################
# CommentListener #
###################

const COMMENT_EVENTS = ["commit_comment",
                        "pull_request",
                        "pull_request_review_comment",
                        "issues",
                        "issue_comment"]

struct CommentListener
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
        return HTTP.Response(204, "payload does not contain comment")
    end

    if check_collab
        repo = event.repository
        user = body_container["user"]["login"]
        if !(iscollaborator(repo, user; auth = auth))
            return HTTP.Response(204, "commenter is not collaborator")
        end
    end

    trigger_match = match(trigger, body_container["body"])

    if trigger_match == nothing
        return HTTP.Response(204, "trigger match not found")
    end

    return handle(event, trigger_match)
end
