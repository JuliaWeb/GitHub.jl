#####################
# WebhookEvent Type #
#####################

type WebhookEvent
    kind::GitHubString
    payload::Dict
    repository::Nullable{Repo}
    sender::Nullable{Owner}
end

function event_from_payload!(kind, data::Dict)
    repository = extract_nullable(data, "repository", Repo)
    sender = extract_nullable(data, "sender", Owner)
    haskey(data, "repository") && delete!(data, "repository")
    haskey(data, "sender") && delete!(data, "sender")
    return WebhookEvent(kind, data, repository, sender)
end

function most_recent_commit_sha(event::WebhookEvent)
    if event.kind == "push"
        return event.payload["after"]
    elseif event.kind == "pull_request"
        return event.payload["pull_request"]["head"]["sha"]
    elseif event.kind == "commit_comment"
        return event.payload["comment"]["commit_id"]
    elseif event.kind == "pull_request_review_comment"
        return event.payload["pull_request"]["head"]["sha"]
    else
        error("most_recent_commit_sha(::Event) not supported for $(event.kind)")
    end
end
