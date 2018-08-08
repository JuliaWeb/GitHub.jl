mutable struct Review <: GitHubType
    pr::Union{PullRequest, Nothing}
    id::Union{Int, Nothing}
    user::Union{Owner, Nothing}
    body::Union{String, Nothing}
    state::Union{String, Nothing}
end

function Review(pr::PullRequest, data::Dict)
    rev = json2github(Review, data)
    rev.pr = pr
    rev
end

namefield(rev::Review) = rev.id

@api_default function reviews(api::GitHubAPI, repo, pr::PullRequest; options...)
    path = "/repos/$(name(repo))/pulls/$(name(pr))/reviews"
    results, page_data = gh_get_paged_json(api, path; options...)
    return map(x->Review(pr, x), results), page_data
end

@api_default function comments(api::GitHubAPI, repo, rev::Review; options...)
    path = "/repos/$(name(repo))/pulls/$(name(rev.pr))/reviews/$(name(rev))/comments"
    results, page_data = gh_get_paged_json(api, path; options...)
    return map(Comment, results), page_data
end

@api_default function reply_to(api::GitHubAPI, repo, r::Review, c::Comment, body; options...)
    create_comment(api, repo, r.pr, :review; params = Dict(
        :body => body,
        :in_reply_to => c.id
    ), options...)
end

@api_default function dismiss_review(api::GitHubAPI, repo::Repo, r::Review; options...)
    gh_put(api, "/repos/$(name(repo))/pulls/$(name(rev.pr))/reviews/$(name(rev))/dismissals")
end
