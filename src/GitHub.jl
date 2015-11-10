module GitHub

##########
# import #
##########

import HttpCommon,
       HttpServer,
       JSON,
       MbedTLS,
       Requests

#############
# Utilities #
#############

# include -------

include("utils/GitHubType.jl")
include("utils/error.jl")
include("utils/pagination.jl")
include("utils/auth.jl")
include("utils/requests.jl")

# export -------

export # GitHubType.jl
       name

export # auth.jl
       authenticate

export # requests.jl
       github_get,
       github_paged_get,
       github_post,
       github_put

##################################
# Owners (Organizations + Users) #
##################################

# misc -------

abstract Owner <: GitHubType

# include -------

include("users/users.jl")
include("users/followers.jl")
include("organizations/organizations.jl")

# export -------

export # users.jl
       User,
       user

export # followers.jl
       followers,
       following

export # organizations.jl
       Organization,
       org,
       orgs

################
# Repositories #
################

# include -------

include("repositories/repositories.jl")
include("repositories/forks.jl")
include("repositories/statistics.jl")
include("repositories/statuses.jl")
include("repositories/collaborators.jl")
include("repositories/contents.jl")
include("repositories/commits.jl")
include("repositories/comments.jl")

# export -------

export # repositories.jl
       Repo,
       repo,
       repos,
       contributors

export # forks.jl
       fork,
       forks

       # statistics.jl
export contributor_stats,
       commit_activity,
       code_frequency,
       participation,
       punch_card

export # statuses.jl
       Status,
       PENDING,
       ERROR,
       FAILURE,
       SUCCESS,
       post_status

export # collaborators.jl
       collaborators,
       iscollaborator,
       add_collaborator,
       remove_collaborator

export # contents.jl
       File,
       contents,
       create_file,
       update_file,
       delete_file,
       readme

export # commits.jl
       Commit

export # comments.jl
       Comment,
       comments

##########
# Issues #
##########

# include -------

include("issues/issues.jl")

# export -------

export # issues.jl
       Issue,
       issue,
       issues,
       create_issue,
       edit_issue

############
# Activity #
############

# include -------

include("activity/events/events.jl")
include("activity/events/listeners.jl")
include("activity/starring.jl")
include("activity/watching.jl")

# export -------

export # starring.jl
       star,
       unstar,
       stargazers,
       starred

export # watching.jl
       watchers,
       watched,
       watching,
       watch,
       unwatch

export # events/events.jl
       payload,
       name,
       repo,
       owner,
       most_recent_commit,
       post_status,
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
       WatchEvent

export # events/listeners.jl
       EventListener,
       CommentListener


end # module GitHub
