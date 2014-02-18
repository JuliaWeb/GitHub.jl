
# Types -------

type User
    id
    email
    name
    login
    blog
    bio
    location
    gravatar_id

    public_repos
    owned_private_repos
    total_private_repos

    public_gists
    private_gists

    followers
    following
    collaborators

    company
    hireable

    updated_at
    created_at

    plan
    user_type
    site_admin
    disk_usage

    function User(data::Dict)
        new(get(data, "id", nothing),
            get(data, "email", nothing),
            get(data, "name", nothing),
            get(data, "login", nothing),
            get(data, "blog", nothing),
            get(data, "bio", nothing),
            get(data, "location", nothing),
            get(data, "gravatar_id", nothing),
            get(data, "public_repos", nothing),
            get(data, "owned_private_repos", nothing),
            get(data, "total_private_repos", nothing),
            get(data, "public_gists", nothing),
            get(data, "private_gists", nothing),
            get(data, "followers", nothing),
            get(data, "following", nothing),
            get(data, "collaborators", nothing),
            get(data, "company", nothing),
            get(data, "hireable", nothing),
            get(data, "updated_at", nothing),
            get(data, "created_at", nothing),
            get(data, "plan", nothing),
            get(data, "type", nothing),
            get(data, "site_admin", nothing),
            get(data, "disk_usage", nothing))
    end
end


# Interface -------

function user(username; auth = AnonymousAuth(), options...)
    user(auth, username; options...)
end

function user(auth::Authorization, username; headers = Dict(), options...)
    authenticate_headers(headers, auth)

    r = get(URI(API_ENDPOINT; path = "/users/$username");
            headers = headers,
            options...)

    handle_error(r)

    User(JSON.parse(r.data))
end
