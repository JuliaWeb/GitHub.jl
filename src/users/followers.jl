function followers(user::AbstractString; auth = AnonymousAuth(), options...)
    followers(auth, user; options...)
end

function followers(user::User; auth = AnonymousAuth(), options...)
    followers(auth, user.login; options...)
end

function followers(auth::Authorization, user; headers = Dict(), result_limit = -1, options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/users/$user/followers")
    pages = get_pages(uri, result_limit; headers = headers, options...)
    items = get_items_from_pages(pages)
    return User[User(i) for i in items]
end

function following(user::AbstractString; auth = AnonymousAuth(), options...)
    following(auth, user; options...)
end

function following(user::User; auth = AnonymousAuth(), options...)
    following(auth, user.login; options...)
end

function following(auth::Authorization, user; headers = Dict(), result_limit = -1, options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/users/$user/following")
    pages = get_pages(uri, result_limit; headers = headers, options...)
    items = get_items_from_pages(pages)
    return User[User(i) for i in items]
end
