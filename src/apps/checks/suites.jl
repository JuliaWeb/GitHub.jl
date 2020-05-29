@ghdef mutable struct CheckSuite
    id::Union{Integer,Nothing}
    head_sha::Union{String,Nothing}
    status::Union{String,Nothing}
    conclusion::Union{String, Nothing}
    app::Union{App,Nothing}
end
namefield(suite::CheckSuite) = suite.id

"""
    GitHub.check_suite([api,] repo::Repo, id; options...)

- https://developer.github.com/v3/checks/suites/#get-a-single-check-suite
"""
@api_default function check_suite(api::GitHubAPI, repo::Repo, id; headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.antiope-preview+json"
    result = gh_get_json(api, "/repos/$(name(repo))/check-suites/$(id)";
        headers=headers, options...)
    CheckSuite(results)
end
"""
    GitHub.check_suites([api,] repo::Repo, ref; options...)

- https://developer.github.com/v3/checks/suites/#list-check-suites-for-a-specific-ref
"""
@api_default function check_suites(api::GitHubAPI, repo::Repo, ref; headers = Dict(), options...)
    headers["Accept"] = "application/vnd.github.antiope-preview+json"
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/commits/$(name(ref))/check-suites";
        headers=headers, options...)
    map(CheckSuite, results["check_suites"]), page_data, results["total_count"]
end
