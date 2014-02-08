
module Octokit

using Requests
using JSON

export authenticate,
       set_api_endpoint,
       set_web_endpoint


include("endpoint.jl")
include("error.jl")
include("auth.jl")
include("starring.jl")

end

