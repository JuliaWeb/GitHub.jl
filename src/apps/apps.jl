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

function app(; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    App(gh_get_json("/app"; headers=headers, kwargs...))
end

function app(id::Int; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    App(gh_get_json("/app/$id"; headers=headers, kwargs...))
end

function app(slug::String; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.machine-man-preview+json"
    App(gh_get_json("/apps/$slug"; headers=headers, kwargs...))
end
