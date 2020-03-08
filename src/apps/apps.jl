@ghdef mutable struct App
    id::Union{Int, Nothing}
    owner::Union{Owner, Nothing}
    name::Union{String, Nothing}
    description::Union{String, Nothing}
    external_url::Union{String, Nothing}
    html_url::Union{String, Nothing}
end

namefield(a::App) = a.id

@api_default function app(api::GitHubAPI; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    App(gh_get_json(api, "/app"; headers=headers, kwargs...))
end

@api_default function app(api::GitHubAPI, id::Int; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    App(gh_get_json(api, "/app/$id"; headers=headers, kwargs...))
end

@api_default function app(api::GitHubAPI, slug::String; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    App(gh_get_json(api, "/apps/$slug"; headers=headers, kwargs...))
end
