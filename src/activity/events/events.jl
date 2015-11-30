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
