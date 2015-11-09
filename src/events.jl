#############
# EventName #
#############

immutable EventName
    name::ASCIIString
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
end

Event(request::HttpCommon.Request, payload) = Event(EventName(request), payload)

payload(event::Event) = event.payload
name(event::Event) = event.name
repo(event::Event) = event.payload["name"]
owner(event::Event) = event.payload["owner"]["login"]

"""
    most_recent_commit(event::GitHub.Event)

Get the SHA of the most recent commit associated with `event`. Applies to:

- `GitHub.PushEvent` -> the commit that got pushed
- `GitHub.PullRequestEvent` -> head commit of PR branch
- `GitHub.CommitCommentEvent` -> commit that was commented on
- `GitHub.PullRequestReviewCommentEvent` -> head commit of PR branch
"""
function most_recent_commit(event::Event)
    event_name, event_payload = name(event), payload(event)
    if event_name == PushEvent
        return event_payload["after"]
    elseif event_name == PullRequestEvent
        return event_payload["pull_request"]["head"]["sha"]
    elseif event_name == CommitCommentEvent
        return event_payload["comment"]["commit_id"]
    elseif event_name == PullRequestReviewCommentEvent
        return event_payload["pull_request"]["head"]["sha"]
    else
        error("most_recent_commit(::Event) not supported for $event_name")
    end
end
