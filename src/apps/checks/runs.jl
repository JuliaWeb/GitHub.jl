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
        caption::Nullable{String}
    end

    struct Annotation
        filename::String
        blob_href::String
        start_line::Int
        end_line::Int
        warning_level::String
        message::String
        title::Nullable{String}
        raw_details::String # Documented as Nullable{String}, but that errors
    end

    struct Output
        title::String
        summary::String
        text::String # Documented as Nullable{String}, but that errors
        annotations::Vector{Annotation}
        images::Vector{Image}
    end

end
using .Checks

struct CheckRun <: GitHubType
    id::Nullable{Int}
    head_sha::Nullable{String}
    external_id::Nullable{String}
    status::Nullable{String}
    conclusion::Nullable{String}
    started_at::Nullable{DateTime}
    completed_at::Nullable{DateTime}
    app::Nullable{App}
    pull_requests::Nullable{Vector{PullRequest}}
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
