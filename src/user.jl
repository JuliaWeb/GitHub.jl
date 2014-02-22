
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
    avatar_url

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
            get(data, "avatar_url", nothing),
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

function show(io::IO, user::User)
    print(io, "$User - $(user.login)")

    if user.name != nothing && !isempty(user.name) && user.email != nothing && !isempty(user.email)
        print(io, " ($(user.name), $(user.email))")
    elseif user.name != nothing
        print(io, " ($(user.name))")
    elseif user.email != nothing
        print(io, " ($(user.email))")
    end

    if user.bio != nothing && !isempty(user.bio)
        print(io, "\n\"$(user.bio)\"")
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


function followers(user::String; auth = AnonymousAuth(), options...)
    followers(auth, user; options...)
end

function followers(user::User; auth = AnonymousAuth(), options...)
    followers(auth, user.login; options...)
end

function followers(auth::Authorization, user; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/users/$user/followers");
            headers = headers,
            options...)

    handle_error(r)

    map!(f -> User(f), JSON.parse(r.data))
end


function following(user::String; auth = AnonymousAuth(), options...)
    following(auth, user; options...)
end

function following(user::User; auth = AnonymousAuth(), options...)
    following(auth, user.login; options...)
end

function following(auth::Authorization, user; headers = Dict(), options...)
    authenticate_headers(headers, auth)
    r = get(URI(API_ENDPOINT; path = "/users/$user/following");
            headers = headers,
            options...)

    handle_error(r)

    map!(f -> User(f), JSON.parse(r.data))
end
