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
include("utils/pagination.jl")
include("utils/auth.jl")
include("utils/requests.jl")

# export -------

export # auth.jl
       authenticate

export # requests.jl
       github_get,
       github_paged_get,
       github_post,
       github_put,
       github_patch,
       github_delete

##################################
# Owners (organizations + users) #
##################################

# include -------

include("owners/owners.jl")

# export -------

export # owners.jl
       Owner,
       user,
       org,
       orgs,
       followers,
       following

################
# Repositories #
################

# include -------

include("repositories/repositories.jl")
include("repositories/contents.jl")
include("repositories/commits.jl")
include("repositories/statuses.jl")
include("repositories/comments.jl")

# export -------

export # repositories.jl
       Repo,
       repo,
       repos,
       fork,
       forks
       contributors
       collaborators,
       iscollaborator,
       add_collaborator,
       remove_collaborator,
       stats

export # commits.jl
       Commit,
       commit,
       commits

export # contents.jl
       Content,
       file,
       directory,
       create_file,
       update_file,
       delete_file,
       readme

export # statuses.jl
       Status,
       create_status,
       statuses

export # comments.jl
       Comment

##########
# Issues #
##########

# include -------

include("issues/pull_requests.jl")
include("issues/issues.jl")

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
       edit_issue,
       issue_comments

############
# Activity #
############

# include -------

include("activity/events/events.jl")
include("activity/events/listeners.jl")
include("activity/activity.jl")

# export -------

export # activity.jl
       star,
       unstar,
       stargazers,
       starred,
       watchers,
       watched,
       watching,
       watch,
       unwatch

export # events/events.jl
       WebhookEvent,
       most_recent_commit

export # events/listeners.jl
       EventListener,
       CommentListener

end # module GitHub
