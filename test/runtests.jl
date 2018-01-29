using GitHub, JSON, HTTP, MbedTLS, Nullables
using Compat, Compat.Dates, Compat.Test
using GitHub: Branch, name

if VERSION >= v"0.7.0-DEV.2338"
    using Base64
end

include("ghtype_tests.jl")
include("event_tests.jl")
include("read_only_api_tests.jl")
include("auth_tests.jl")
