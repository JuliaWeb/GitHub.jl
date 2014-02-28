# Types -------

type Issue
    id
    number
    title
    user
    labels
    state
    assignee
    milestone
    comments
    created_at
    updated_at
    closed_at
    pull_request
    body

    function Issue(data::Dict)
        new(get(data, "id", nothing),
            get(data, "number", nothing),
            get(data, "title", nothing),
            User(get(data, "user", Dict())),
            get(data, "labels", nothing),
            get(data, "state", nothing),
            get(data, "assignee", nothing),
            get(data, "milestone", nothing),
            get(data, "comments", nothing),
            get(data, "created_at", nothing),
            get(data, "updated_at", nothing),
            get(data, "closed_at", nothing),
            get(data, "pull_request", nothing),
            get(data, "body", nothing))
    end
end

function show(io::IO, issue::Issue)
    print(io, "$Issue #$(issue.number)")

    if issue.title != nothing && !isempty(issue.title)
        print(io, " - \"$(issue.title)\"")
    end
end


# Interface -------

function issue(user::String, repo, num; auth = AnonymousAuth(), options...)
    issue(auth, user, repo, num; options...)
end

function issue(user::User, repo, num; auth = AnonymousAuth(), options...)
    issue(auth, user.login, repo, num; options...)
end

function issue(auth::Authorization, user::String, repo, num; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/repos/$user/$repo/issues/$num");
            headers = headers,
            options...)

    handle_error(r)

    Issue(JSON.parse(r.data))
end
