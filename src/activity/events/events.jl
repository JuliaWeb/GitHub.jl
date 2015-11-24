#####################
# WebhookEvent Type #
#####################

type WebhookEvent
    kind::GitHubString
    payload::Dict
    repository::Nullable{Repo}
    sender::Nullable{Owner}
end

function event_from_payload!(name, data::Dict)
    repository = extract_nullable(data, "repository", Repo)
    sender = extract_nullable(data, "sender", Owner)
    haskey(data, "repository") && delete!(data, "repository")
    haskey(data, "sender") && delete!(data, "sender")
    return WebhookEvent(name, data, repository, sender)
end

function most_recent_commit(event::WebhookEvent)
    if event.kind == "push"
        return event.payload["after"]
    elseif event.kind == "pull_request"
        return event.payload["pull_request"]["head"]["sha"]
    elseif event.kind == "commit_comment"
        return event.payload["comment"]["commit_id"]
    elseif event.kind == "pull_request_review_comment"
        return event.payload["pull_request"]["head"]["sha"]
    else
        error("most_recent_commit(::Event) not supported for $(event.kind)")
    end
end

function create_status(event::WebhookEvent, sha; options...)
    repo = get(event.repository)
    owner = get(repo.owner)
    return create_status(owner, repo, sha; options...)
end
