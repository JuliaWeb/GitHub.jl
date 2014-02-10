
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
       stargazers,
       starred


include("endpoint.jl")
include("error.jl")
include("auth.jl")
include("user.jl")
include("starring.jl")

end

