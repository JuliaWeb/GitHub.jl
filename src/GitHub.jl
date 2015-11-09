
module GitHub

import Base.show

import JSON, HttpServer, MbedTLS
using Compat
using HttpCommon
using Requests
import Requests: get, post, put, delete, options

if VERSION < v"0.4-"
    using Dates
else
    using Base.Dates
end

abstract GitHubType
abstract Owner <: GitHubType


# types
export User,
       Organization,
       Repo,
       Issue,
       Comment,
       File,
       Commit,
       HttpError,
       AuthError,
       StatsError,
       Status,
       PENDING,
       ERROR,
       FAILURE,
       SUCCESS,
       CommitCommentEvent,
       CreateEvent,
       DeleteEvent,
       DeploymentEvent,
       DeploymentStatusEvent,
       DownloadEvent,
       FollowEvent,
       ForkEvent,
       ForkApplyEvent,
       GistEvent,
       GollumEvent,
       IssueCommentEvent,
       IssuesEvent,
       MemberEvent,
       MembershipEvent,
       PageBuildEvent,
       PublicEvent,
       PullRequestEvent,
       PullRequestReviewCommentEvent,
       PushEvent,
       ReleaseEvent,
       RepositoryEvent,
       StatusEvent,
       TeamAddEvent,
       WatchEvent,
       EventListener

# methods
export authenticate,
       set_api_endpoint,
       set_web_endpoint,
       user,
       star,
       unstar,
       stargazers,
       starred,
       forks,
       fork,
       contributors,
       contributor_stats,
       commit_activity,
       code_frequency,
       participation,
       punch_card,
       collaborators,
       iscollaborator,
       add_collaborator,
       remove_collaborator,
       watchers,
       watched,
       watching,
       watch,
       unwatch,
       followers,
       following,
       org,
       orgs,
       repo,
       repos,
       issue,
       create_issue,
       edit_issue,
       issues,
       comments,
       contents,
       create_file,
       update_file,
       delete_file,
       readme,
       post_status,
       repo,
       owner,
       most_recent_commit,
       payload,
       name



include("utils.jl")
include("endpoint.jl")
include("error.jl")
include("auth.jl")
include("users.jl")
include("organizations.jl")
include("repos.jl")
include("issues.jl")
include("comments.jl")
include("starring.jl")
include("forks.jl")
include("statistics.jl")
include("collaborators.jl")
include("watching.jl")
include("contents.jl")
include("events.jl")
include("statuses.jl")
include("event_listeners.jl")


end
