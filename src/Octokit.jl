
module Octokit

using Requests
using JSON
using HttpCommon

export authenticate,
       set_api_endpoint,
       set_web_endpoint,
       stargazers


include("endpoint.jl")
include("error.jl")
include("auth.jl")
include("starring.jl")

end

