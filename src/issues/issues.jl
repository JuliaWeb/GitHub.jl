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

    if issue.state != nothing && !isempty(issue.state)
        print(io, " ($(issue.state))")
    end

    if issue.title != nothing && !isempty(issue.title)
        print(io, " - \"$(issue.title)\"")
    end
end

# Interface -------

function issue(owner::AbstractString, repo, num; auth = AnonymousAuth(), options...)
    issue(auth, owner, repo, num; options...)
end

function issue(owner::Owner, repo, num; auth = AnonymousAuth(), options...)
    issue(auth, owner.login, repo, num; options...)
end

function issue(auth::Authorization, owner::AbstractString, repo, num; headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/issues/$num");
            headers = headers,
            options...)

    handle_error(r)

    Issue(Requests.json(r))
end


function issues(owner::AbstractString, repo; auth = AnonymousAuth(), options...)
    issues(auth, owner, repo; options...)
end

function issues(owner::Owner, repo; auth = AnonymousAuth(), options...)
    issues(auth, owner.login, repo; options...)
end

function issues(auth::Authorization, owner::AbstractString, repo; milestone = nothing,
                                                          state = nothing,
                                                          assignee = nothing,
                                                          creator = nothing,
                                                          mentioned = nothing,
                                                          labels = nothing,
                                                          sort = nothing,
                                                          direction = nothing,
                                                          since = nothing,
                                                          headers = Dict(),
                                                          query = Dict(),
                                                          result_limit = -1,
                                                          options...)
    authenticate_headers!(headers, auth)

    milestone != nothing && (query["milestone"] = milestone)
    state != nothing && (query["state"] = state)
    assignee != nothing && (query["assignee"] = assignee)
    creator != nothing && (query["creator"] = creator)
    mentioned != nothing && (query["mentioned"] = mentioned)
    labels != nothing && (query["labels"] = labels)
    sort != nothing && (query["sort"] = sort)
    direction != nothing && (query["direction"] = direction)
    since != nothing && (query["since"] = since)

    pages = get_pages(URI(API_ENDPOINT; path = "/repos/$owner/$repo/issues"), result_limit;
                      headers = headers,
                      query = query,
                      options...)
    items = get_items_from_pages(pages)
    return Issue[Issue(i) for i in items]
end


function create_issue(owner::AbstractString, repo, title; auth = AnonymousAuth(), options...)
    create_issue(auth, owner, repo, title; options...)
end

function create_issue(owner::Owner, repo, title; auth = AnonymousAuth(), options...)
    create_issue(auth, owner.login, repo, title; options...)
end

function create_issue(auth::Authorization, owner::AbstractString, repo, title; body = nothing,
                                                                       assignee = nothing,
                                                                       milestone = nothing,
                                                                       labels = nothing,
                                                                       headers = Dict(),
                                                                       json = Dict(),
                                                                       options...)
    authenticate_headers!(headers, auth)

    json["title"] = title
    body != nothing && (json["body"] = body)
    assignee != nothing && (json["assignee"] = assignee)
    milestone != nothing && (json["milestone"] = milestone)
    labels != nothing && (json["labels"] = labels)

    r = post(URI(API_ENDPOINT; path = "/repos/$owner/$repo/issues");
             headers = headers,
             json = json,
             options...)

    handle_error(r)

    Issue(Requests.json(r))
end


function edit_issue(owner::AbstractString, repo, num; auth = AnonymousAuth(), options...)
    edit_issue(auth, owner, repo, num; options...)
end

function edit_issue(owner::Owner, repo, num; auth = AnonymousAuth(), options...)
    edit_issue(auth, owner.login, repo, num; options...)
end

function edit_issue(auth::Authorization, owner::AbstractString, repo, num; title = nothing,
                                                                   body = nothing,
                                                                   assignee = nothing,
                                                                   state = nothing,
                                                                   milestone = nothing,
                                                                   labels = nothing,
                                                                   headers = Dict(),
                                                                   json = Dict(),
                                                                   options...)
    authenticate_headers!(headers, auth)

    title != nothing && (json["title"] = title)
    body != nothing && (json["body"] = body)
    assignee != nothing && (json["assignee"] = assignee)
    state != nothing && (json["state"] = state)
    milestone != nothing && (json["milestone"] = milestone)
    labels != nothing && (json["labels"] = labels)

    r = patch(URI(API_ENDPOINT; path = "/repos/$owner/$repo/issues/$num");
             headers = headers,
             json = json,
             options...)

    handle_error(r)

    Issue(Requests.json(r))
end
