
# Types -------

abstract GitHubException <: Base.Exception


type AuthError <: GitHubException
    status
    message
    url
end


type StatsError <: GitHubException
    message
end


type HttpError <: GitHubException
    status
    message
    url
end


# Utility -------

function handle_error(r::Response)
    if r.status < 400
        return
    end

    data = JSON.parse(r.data)

    if r.status < 600
        throw(HttpError(r.status, get(data, "message", ""), get(data, "documentation_url", "")))
    end

    warn("unknown status in http response: \n", r)
end
