type App <: GitHubType
    id::Nullable{Int}
    owner::Nullable{Owner}
    name::Nullable{String}
    description::Nullable{String}
    external_url::Nullable{String}
    html_url::Nullable{String}
end

namefield(a::App) = a.id
App(data::Dict) = json2github(App, data)

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
