###############
# Branch Type #
###############

type Branch <: GitHubType
    label::Nullable{GitHubString}
    ref::Nullable{GitHubString}
    sha::Nullable{GitHubString}
    user::Nullable{Owner}
    repo::Nullable{Repo}
end

Branch(data::Dict) = json2github(Branch, data)

urifield(branch::Branch) = branch.ref

####################
# PullRequest Type #
####################

type PullRequest <: GitHubType
    base::Nullable{Branch}
    head::Nullable{Branch}
    number::Nullable{Int}
    id::Nullable{Int}
    comments::Nullable{Int}
    commits::Nullable{Int}
    additions::Nullable{Int}
    deletions::Nullable{Int}
    changed_files::Nullable{Int}
    state::Nullable{GitHubString}
    title::Nullable{GitHubString}
    body::Nullable{GitHubString}
    merge_commit_sha::Nullable{GitHubString}
    created_at::Nullable{Dates.DateTime}
    updated_at::Nullable{Dates.DateTime}
    closed_at::Nullable{Dates.DateTime}
    merged_at::Nullable{Dates.DateTime}
    url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    assignee::Nullable{Owner}
    user::Nullable{Owner}
    merged_by::Nullable{Owner}
    milestone::Nullable{Dict}
    _links::Nullable{Dict}
    mergeable::Nullable{Bool}
    merged::Nullable{Bool}
    locked::Nullable{Bool}
end

PullRequest(data::Dict) = json2github(PullRequest, data)

urifield(pr::PullRequest) = pr.number

###############
# API Methods #
###############

function pull_requests(owner, repo; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/pulls"
    return map(PullRequest, github_paged_get(path; options...))
end

function pull_request(owner, repo, pr; options...)
    path = "/repos/$(urirepr(owner))/$(urirepr(repo))/pulls/$(urirepr(pr))"
    return PullRequest(github_get_json(path; options...))
end
