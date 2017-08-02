type Installation <: GitHubType
    id::Nullable{Int}
end

namefield(i::Installation) = i.id

Installation(data::Dict) = json2github(Installation, data)
Installation(id::Int) = Installation(Dict("id" => id))

function create_access_token(i::Installation, auth::JWTAuth; headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    payload = gh_post_json("/installations/$(get(i.id))/access_tokens", auth = auth,
        headers=headers, options...)
    OAuth2(payload["token"])
end
