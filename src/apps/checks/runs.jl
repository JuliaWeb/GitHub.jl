@ghdef mutable struct CheckRun
    name::Union{String,Nothing}
    details_url::Union{String,Nothing}
    external_id::Union{String,Nothing}
    started_at::Union{DateTime, Nothing}
    status::Union{String,Nothing}
    conclusion::Union{String, Nothing}
    completed_at::Union{DateTime, Nothing}
    output::Union{Output, Nothing}
    actions::Union{Vector{Action}, Nothing}

    # output
    id::Union{Int, Nothing}
    head_sha::Union{String, Nothing}
    app::Union{App, Nothing}
    pull_requests::Union{Vector{PullRequest}, Nothing}
    check_suite::Union{CheckSuite, Nothing}
    html_url::Union{HTTP.URI, Nothing}
end
namefield(cr::CheckRun) = cr.id

"""
    GitHub.check_runs([api,] repo::Repo, suite::CheckSuite; options...)

# Parameters
 - `check_name::String`: Returns check runs with the specified `name`.
 - `status::String`: Returns check runs with the specified `status`. Can be one of `"queued"`, `"in_progress"`, or `"completed"`.
 - `filter::String`: Filters check runs by their `completed_at` timestamp. Can be one of `"latest"` (returning the most recent check runs) or `"all"`. Default: `"latest"`

# External links
- https://developer.github.com/v3/checks/runs/#list-check-runs-in-a-check-suite
"""
@api_default function check_runs(api::GitHubAPI, repo::Repo, suite::CheckSuite; headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.antiope-preview+json"
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/check-suites/$(name(suite))/check-runs";
        headers=headers, options...)
    map(CheckRun, results["check_runs"]), page_data, results["total_count"]
end

"""
    GitHub.check_runs([api,] repo::Repo, ref; options...)

List the `CheckRun`s for `ref`

# Parameters
 - `check_name::String`: Returns check runs with the specified `name`.
 - `status::String`: Returns check runs with the specified `status`. Can be one of `"queued"`, `"in_progress"`, or `"completed"`.
 - `filter::String`: Filters check runs by their `completed_at` timestamp. Can be one of `"latest"` (returning the most recent check runs) or `"all"`. Default: `"latest"`

# External links
- https://developer.github.com/v3/checks/runs/#list-check-runs-for-a-specific-ref
"""
@api_default function check_runs(api::GitHubAPI, repo::Repo, ref; headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.antiope-preview+json"
    results, page_data, total_count = gh_get_paged_json(api, "/repos/$(name(repo))/commits/$(ref)/check-runs", "check_runs";
                                           headers=headers, options...)
    map(CheckRun, results), page_data, total_count
end


"""
    GitHub.create_check_run([api,] repo::Repo; options...)

- https://developer.github.com/v3/checks/runs/#create-a-check-run
"""
@api_default function create_check_run(api::GitHubAPI, repo::Repo; headers = Dict(), kwargs...)
    headers["Accept"] = "application/vnd.github.antiope-preview+json"
    result = gh_post_json(api, "/repos/$(name(repo))/check-runs"; headers=headers, kwargs...)
    return CheckRun(result)
end

"""
    GitHub.update_check_run([api,] repo::Repo, cr::CheckRun; options...)

- https://developer.github.com/v3/checks/runs/#update-a-check-run
"""
@api_default function update_check_run(api::GitHubAPI, repo::Repo, cr::CheckRun; kwargs...)
    update_check_run(api, repo, cr.id; kwargs...)
end
@api_default function update_check_run(api::GitHubAPI, repo::Repo, id::Int; headers = Dict(), kwargs...)
    # TODO: deprecate?
    headers["Accept"] = "application/vnd.github.antiope-preview+json"
    result = gh_patch_json(api, "/repos/$(name(repo))/check-runs/$(id)"; headers=headers, kwargs...)
    return CheckRun(result)
end
