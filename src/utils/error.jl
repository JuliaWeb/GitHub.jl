
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

function handle_error(r::HttpCommon.Response)
    if r.status >= 400
        data = Requests.json(r)

        if r.status < 600
            message = get(data, "message", "")
            docs_url = get(data, "documentation_url", "")
            throw(HttpError(r.status, message, docs_url))
        end

        warn("unknown status in http response: \n", r)
    end
end
