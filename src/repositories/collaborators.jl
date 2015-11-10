
# Interface -------

function collaborators(repo::Repo; auth = AnonymousAuth(), options...)
    collaborators(auth, repo.owner.login, repo.name; options...)
end

function collaborators(owner::Owner, repo; auth = AnonymousAuth(), options...)
    collaborators(auth, owner.login, repo; options...)
end

function collaborators(owner, repo; auth = AnonymousAuth(), options...)
    collaborators(auth, owner, repo; options...)
end

function collaborators(auth::Authorization, owner, repo; result_limit = -1, headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/collaborators")
    pages = get_pages(uri, result_limit; headers = headers, options...)
    items = get_items_from_pages(pages)
    return User[User(i) for i in items]
end


function iscollaborator(owner, repo, user; auth = AnonymousAuth(), options...)
    iscollaborator(auth, owner, repo, user; options...)
end

function iscollaborator(auth::Authorization, owner, repo, user; headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/collaborators/$user")
    r = Requests.get(uri; headers = headers, options...)
    r.status == 204 && return true
    r.status == 404 && return false
    handle_error(r)  # 404 is not an error in this case
    return false  # at this point, assume no
end


function add_collaborator(owner, repo, user; auth = AnonymousAuth(), options...)
    add_collaborator(auth, owner, repo, user; options...)
end

function add_collaborator(auth::Authorization, owner, repo, user; headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/collaborators/$user")
    r = Requests.put(uri; headers = headers, options...)
    handle_error(r)
end


function remove_collaborator(owner, repo, user; auth = AnonymousAuth(), options...)
    remove_collaborator(auth, owner, repo, user; options...)
end

function remove_collaborator(auth::Authorization, owner, repo, user; headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    uri = api_uri("/repos/$owner/$repo/collaborators/$user")
    r = Requests.delete(uri; headers = headers, options...)
    handle_error(r)
end
