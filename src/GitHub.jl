module GitHub

using Compat

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
include("utils/auth.jl")
include("utils/requests.jl")

# export -------

export # auth.jl
       authenticate

export # requests.jl
       rate_limit

##################################
# Owners (organizations + users) #
##################################

# include -------

include("owners/owners.jl")

# export -------

export # owners.jl
       Owner,
       owner,
       orgs,
       users,
       followers,
       following,
       repos

################
# Repositories #
################

# include -------

include("repositories/repositories.jl")
include("repositories/contents.jl")
include("repositories/commits.jl")
include("repositories/branches.jl")
include("repositories/statuses.jl")

# export -------

export # repositories.jl
       Repo,
       repo,
       create_fork,
       forks,
       contributors,
       collaborators,
       iscollaborator,
       add_collaborator,
       remove_collaborator,
       stats

export # contents.jl
       Content,
       file,
       directory,
       create_file,
       update_file,
       delete_file,
       readme,
       permalink

export # commits.jl
       Commit,
       commit,
       commits

export # branches.jl
       Branch,
       branch,
       branches

export # statuses.jl
       Status,
       create_status,
       statuses,
       status

##########
# Issues #
##########

# include -------

include("issues/pull_requests.jl")
include("issues/issues.jl")
include("issues/comments.jl")

# export -------

export # pull_requests.jl
       PullRequest,
       pull_requests,
       pull_request

export # issues.jl
       Issue,
       issue,
       issues,
       create_issue,
       edit_issue

export # comments.jl
       Comment,
       comment,
       comments,
       create_comment,
       edit_comment,
       delete_comment

############
# Activity #
############

# include -------

include("activity/events.jl")
include("activity/activity.jl")

# export -------

export # activity.jl
       star,
       unstar,
       stargazers,
       starred,
       watchers,
       watched,
       watch,
       unwatch

export # events/events.jl
       WebhookEvent

export # events/listeners.jl
       EventListener,
       CommentListener

end # module GitHub
