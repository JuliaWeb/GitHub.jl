
# Types -------

type Repo <: GitHubType
    id
    owner
    name
    full_name
    description
    private
    fork
    homepage
    language
    forks_count
    stargazers_count
    watchers_count
    size
    default_branch
    master_branch
    open_issues_count
    pushed_at
    created_at
    updated_at
    subscribers_count
    organization
    parent
    source
    has_issues
    has_wiki
    has_downloads

    function Repo(data::Dict)
        r = new(get(data, "id", nothing),
                github_obj_from_type(get(data, "owner", Dict())),
                get(data, "name", nothing),
                get(data, "full_name", nothing),
                get(data, "description", nothing),
                get(data, "private", nothing),
                get(data, "fork", nothing),
                get(data, "homepage", nothing),
                get(data, "language", nothing),
                get(data, "forks_count", nothing),
                get(data, "stargazers_count", nothing),
                get(data, "watchers_count", nothing),
                get(data, "size", nothing),
                get(data, "default_branch", nothing),
                get(data, "master_branch", nothing),
                get(data, "open_issues_count", nothing),
                get(data, "pushed_at", nothing),
                get(data, "created_at", nothing),
                get(data, "updated_at", nothing),
                get(data, "subscribers_count", nothing),
                github_obj_from_type(get(data, "organization", Dict())),
                get(data, "parent", nothing),
                get(data, "source", nothing),
                get(data, "has_issues", nothing),
                get(data, "has_wiki", nothing),
                get(data, "has_downloads", nothing))

        r.parent != nothing && (r.parent = Repo(r.parent))
        r.source != nothing && (r.source = Repo(r.source))
        r
    end
end

function show(io::IO, repo::Repo)
    print(io, "Repo - $(repo.full_name)")
    repo.homepage != nothing && !isempty(repo.homepage) && print(io, " ($(repo.homepage))")
    repo.description != nothing && !isempty(repo.description) && print(io, "\n\"$(repo.description)\"")
end


# Interface -------

function repo(owner, repo_name; auth = AnonymousAuth(), options...)
    repo(auth, owner, repo_name; options...)
end

function repo(auth::Authorization, owner, repo_name; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo_name");
            headers = headers,
            options...)

    handle_error(r)

    Repo(JSON.parse(r.data))
end

function repos(owner::User; auth = AnonymousAuth(), options...)
  repos(auth, "/users/$(owner.login)"; options...)
end

function repos(owner::Organization; auth = AnonymousAuth(), options...)
  repos(auth, "/orgs/$(owner.login)"; options...)
end

function repos(auth::Authorization, owner; typ = nothing, # for user: all, member, [owner]
                                                          # for org: [all], public, private, forks, sources, member
                                           sort = nothing, # created, updated, pushed, [full_name]
                                           direction = nothing, # asc, [desc]
                                           headers = Dict(),
                                           data = Dict(),
                                           options...)
  authenticate_headers(headers, auth)

  typ == nothing || (data["type"] = typ)
  sort == nothing || (data["sort"] = sort)
  direction == nothing || (data["direction"] = direction)

  r = get(URI(API_ENDPOINT; path = "$owner/repos");
                            headers = headers,
                            query = data,
                            options...)

  handle_error(r)

  # Handle Pagination Links
  results = JSON.parse(r.data)
  links = parse_link_header(r.headers["Link"])
  while haskey(links,"next")
    r = get(links["next"])
    handle_error(r)

    append!(results,JSON.parse(r.data))
    links = parse_link_header(r.headers["Link"])
  end

  Repo[Repo(d) for d in results]
end
