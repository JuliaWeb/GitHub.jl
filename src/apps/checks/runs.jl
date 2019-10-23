@ghdef mutable struct CheckRun
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
