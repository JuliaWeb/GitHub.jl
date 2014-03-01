
module GitHub

import Base.show

using Requests
using JSON
using HttpCommon

# types
export User,
       Organization,
       Repo,
       Issue,
       HttpError,
       AuthError,
       StatsError

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
       issue,
       create_issue


include("utils.jl")
include("endpoint.jl")
include("error.jl")
include("auth.jl")
include("users.jl")
include("organizations.jl")
include("repos.jl")
include("issues.jl")
include("starring.jl")
include("forks.jl")
include("statistics.jl")
include("collaborators.jl")
include("watching.jl")


end

