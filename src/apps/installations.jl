@ghdef mutable struct Installation
    id::Union{Int, Nothing}
end

namefield(inst::Installation) = inst.id


"""
    GitHub.create_access_token([api,] inst::Installation; 
        auth::JWTAuth=jwt, options...)

Create an `OAuth2` access token for the `App` authenticated by `jwt` to make authenticated API
requests to the installation `inst` on an organization or individual account.

- https://developer.github.com/v3/apps/#create-a-new-installation-token
"""
@api_default function create_access_token(api::GitHubAPI, inst::Installation; auth::JWTAuth, headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    payload = gh_post_json(api, "/installations/$(inst.id)/access_tokens", auth = auth,
        headers=headers, options...)
    OAuth2(payload["token"])
end
@api_default function create_access_token(api::GitHubAPI, inst::Installation, auth::JWTAuth; options...)
    create_access_token(api, inst; auth=auth, options...)
end

"""
    GitHub.installation([api,] repo::Repo;
        auth::JWTAuth=jwt, options...)

Get the `Installation` on `repo` of the `App` authenticated by `jwt`.

- https://developer.github.com/v3/apps/#get-a-repository-installation
"""
@api_default function installation(api::GitHubAPI, repo::Repo; auth::JWTAuth, headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    result = gh_get_json(api, "/repos/$(name(repo))/installation", auth = auth,
        headers=headers, options...)
    Installation(result)
end
@api_default function installation(api::GitHubAPI, repo::Repo, auth::JWTAuth; options...)
    # TODO: deprecate
    installation(api, repo; auth=auth, options...)
end

"""
    insts, pagedata = GitHub.installations([api]; 
        auth::JWTAuth=jwt, options...)

List all `Installation`s corresponding to the app authenticated by `jwt`.

- https://developer.github.com/v3/apps/#list-installations
"""
@api_default function installations(api::GitHubAPI; auth::JWTAuth, headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    results, page_data = gh_get_paged_json(api, "/app/installations";
        auth=auth, headers=headers, options...)
    map(Installation, results), page_data
end
@api_default function installations(api::GitHubAPI, auth::JWTAuth; options...)
    # TODO: deprecate
    installations(api; auth=auth, options...)
end

"""
    repos, pagedata = GitHub.repos([api]; 
        auth::OAuth=token, options...)

List `Repo`s that the installation corresponding to `token` can access.

- https://developer.github.com/v3/apps/installations/#list-repositories
"""
@api_default function repos(api::GitHubAPI; auth::OAuth2, headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    results, page_data = github_paged_get(api, "/installation/repositories";
        auth=auth, headers=headers, options...)
    mapreduce(x->map(Repo, JSON.parse(HTTP.payload(x, String))["repositories"]), vcat, results; init=Repo[]), page_data
end
@api_default function repos(api::GitHubAPI, inst::Installation; options...)
    # TODO: deprecate
    repos(api; options...)
end
