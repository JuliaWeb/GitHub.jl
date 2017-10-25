mutable struct App <: GitHubType
    id           :: ?{Int}
    owner        :: ?{Owner}
    name         :: ?{String}
    description  :: ?{String}
    external_url :: ?{String}
    html_url     :: ?{String}
end

name(a::App) = a.id
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
