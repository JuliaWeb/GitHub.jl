
module Octokit

using Requests
using JSON
using HttpCommon


export HttpError,
       AuthException


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
       punch_card


include("endpoint.jl")
include("error.jl")
include("auth.jl")
include("user.jl")
include("starring.jl")
include("forks.jl")
include("statistics.jl")

end

