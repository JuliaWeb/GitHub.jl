module Checks
    export Action, Image, Annotation, Output

    struct Action
        label::String
        description::String
        identifier::String
    end

    struct Image
        alt::String
        image_url::String
        caption::Union{String, Nothing}
    end

    struct Annotation
        filename::String
        blob_href::String
        start_line::Int
        end_line::Int
        warning_level::String
        message::String
        title::Union{String, Nothing}
        raw_details::String # Documented as Union{String, Nothing}, but that errors
    end

    struct Output
        title::String
        summary::String
        text::String # Documented as Union{String, Nothing}, but that errors
        annotations::Vector{Annotation}
        images::Vector{Image}
    end

end
using .Checks

struct CheckRun <: GitHubType
    id::Union{Int, Nothing}
    head_sha::Union{String, Nothing}
    external_id::Union{String, Nothing}
    status::Union{String, Nothing}
    conclusion::Union{String, Nothing}
    started_at::Union{DateTime, Nothing}
    completed_at::Union{DateTime, Nothing}
    app::Union{App, Nothing}
    pull_requests::Union{Vector{PullRequest}, Nothing}
end
CheckRun(data::Dict) = json2github(CheckRun, data)
namefield(cr::CheckRun) = cr.id

@api_default function create_check_run(api::GitHubAPI, repo::Repo; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.antiope-preview+json"
    result = gh_post_json(api, "/repos/$(name(repo))/check-runs"; headers=headers, kwargs...)
    return CheckRun(result)
end

@api_default function update_check_run(api::GitHubAPI, repo::Repo, id::Int; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.antiope-preview+json"
    result = gh_patch_json(api, "/repos/$(name(repo))/check-runs/$(id)"; headers=headers, kwargs...)
    return CheckRun(result)
end
