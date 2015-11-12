#############
# EventName #
#############

immutable EventName
    name::GitHubString
end

has_event_header(request::HttpCommon.Request) = haskey(request.headers, "X-GitHub-Event")
event_header(request::HttpCommon.Request) = request.headers["X-GitHub-Event"]

EventName(request::HttpCommon.Request) = EventName(event_header(request))

Base.(:(==))(a::EventName, b::EventName) = a.name == b.name

const CommitCommentEvent = EventName("commit_comment")
const CreateEvent = EventName("create")
const DeleteEvent = EventName("delete")
const DeploymentEvent = EventName("deployment")
const DeploymentStatusEvent = EventName("deployment_status")
const DownloadEvent = EventName("download")
const FollowEvent = EventName("follow")
const ForkEvent = EventName("fork")
const ForkApplyEvent = EventName("fork_apply")
const GistEvent = EventName("gist")
const GollumEvent = EventName("gollum")
const IssueCommentEvent = EventName("issue_comment")
const IssuesEvent = EventName("issues")
const MemberEvent = EventName("member")
const MembershipEvent = EventName("membership")
const PageBuildEvent = EventName("page_build")
const PublicEvent = EventName("public")
const PullRequestEvent = EventName("pull_request")
const PullRequestReviewCommentEvent = EventName("pull_request_review_comment")
const PushEvent = EventName("push")
const ReleaseEvent = EventName("release")
const RepositoryEvent = EventName("repository")
const StatusEvent = EventName("status")
const TeamAddEvent = EventName("team_add")
const WatchEvent = EventName("watch")

##############
# Event Type #
##############

type Event
    name::EventName
    payload::Dict
    repository::Nullable{Repo}
    sender::Nullable{Owner}
end

function event_from_payload!(name::EventName, payload::Dict)
    repository = extract_nullable(payload, "repository", Repo)
    sender = extract_nullable(payload, "sender", Owner)
    haskey("repository") && delete!(payload, "repository")
    haskey("sender") && delete!(payload, "sender")
    return Event(name, payload, repository, sender)
end

"""
    most_recent_commit(event::GitHub.Event)

Get the SHA of the most recent commit associated with `event`. Applies to:

- `GitHub.PushEvent` -> the commit that got pushed
- `GitHub.PullRequestEvent` -> head commit of PR branch
- `GitHub.CommitCommentEvent` -> commit that was commented on
- `GitHub.PullRequestReviewCommentEvent` -> head commit of PR branch
"""
function most_recent_commit(event::Event)
    if event.name == PushEvent
        return event.payload["after"]
    elseif event.name == PullRequestEvent
        return event.payload["pull_request"]["head"]["sha"]
    elseif event.name == CommitCommentEvent
        return event.payload["comment"]["commit_id"]
    elseif event.name == PullRequestReviewCommentEvent
        return event.payload["pull_request"]["head"]["sha"]
    else
        error("most_recent_commit(::Event) not supported for $(event.name)")
    end
end

function create_status(event::Event, sha; options...)
    repo = get(event.repository)
    owner = get(repo.owner)
    return create_status(owner, repo, sha; options...)
end
