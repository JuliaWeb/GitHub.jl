
# Types -------

type Organization <: Owner
    id
    email
    name
    login
    blog
    bio
    location
    gravatar_id
    avatar_url
    company

    public_repos
    owned_private_repos
    total_private_repos

    public_gists
    private_gists

    followers
    following
    collaborators

    updated_at
    created_at

    plan
    user_type
    site_admin
    disk_usage

    function Organization(data::Dict)
        new(get(data, "id", nothing),
            get(data, "email", nothing),
            get(data, "name", nothing),
            get(data, "login", nothing),
            get(data, "blog", nothing),
            get(data, "bio", nothing),
            get(data, "location", nothing),
            get(data, "gravatar_id", nothing),
            get(data, "avatar_url", nothing),
            get(data, "company", nothing),
            get(data, "public_repos", nothing),
            get(data, "owned_private_repos", nothing),
            get(data, "total_private_repos", nothing),
            get(data, "public_gists", nothing),
            get(data, "private_gists", nothing),
            get(data, "followers", nothing),
            get(data, "following", nothing),
            get(data, "collaborators", nothing),
            get(data, "updated_at", nothing),
            get(data, "created_at", nothing),
            get(data, "plan", nothing),
            get(data, "type", nothing),
            get(data, "site_admin", nothing),
            get(data, "disk_usage", nothing))
    end
end

function Base.show(io::IO, org::Organization)
    print(io, "$User - $(org.login)")

    if org.name != nothing && !isempty(org.name) && org.blog != nothing && !isempty(org.blog)
        print(io, " ($(org.name), $(org.blog))")
    elseif org.name != nothing
        print(io, " ($(org.name))")
    elseif org.blog != nothing
        print(io, " ($(org.blog))")
    end

    if org.bio != nothing && !isempty(org.bio)
        print(io, "\n\"$(org.bio)\"")
    end
end


# Interface -------

function org(name; auth = AnonymousAuth(), options...)
    org(auth, name; options...)
end

function org(auth::Authorization, name; headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    r = Requests.get(api_uri("/orgs/$name"); headers = headers, options...)
    handle_error(r)
    Organization(Requests.json(r))
end


function orgs(user::AbstractString; auth = AnonymousAuth(), options...)
    orgs(auth, user; options...)
end

function orgs(user::User; auth = AnonymousAuth(), options...)
    orgs(auth, user.login; options...)
end

function orgs(auth::Authorization, user; headers = Dict(), result_limit = -1, options...)
    authenticate_headers!(headers, auth)
    pages = get_pages(api_uri("/users/$user/orgs"), result_limit; headers = headers, options...)
    items = get_items_from_pages(pages)
    return Organization[Organization(i) for i in items]
end
