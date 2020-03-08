@ghdef mutable struct Installation
    id::Union{Int, Nothing}
end

namefield(i::Installation) = i.id


@api_default function create_access_token(api::GitHubAPI, i::Installation, auth::JWTAuth; headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    payload = gh_post_json(api, "/installations/$(i.id)/access_tokens", auth = auth,
        headers=headers, options...)
    OAuth2(payload["token"])
end

@api_default function installations(api::GitHubAPI, auth::JWTAuth; headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    results, page_data = gh_get_paged_json(api, "/app/installations", auth = auth,
        headers=headers, options...)
    map(Installation, results), page_data
end

@api_default function repos(api::GitHubAPI, inst::Installation; headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    results, page_data = github_paged_get(api, "/installation/repositories";
        headers=headers, options...)
    mapreduce(x->map(Repo, JSON.parse(HTTP.payload(x, String))["repositories"]), vcat, results; init=Repo[]), page_data
end
