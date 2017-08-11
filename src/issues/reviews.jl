type Review <: GitHubType
    pr::Nullable{PullRequest}
    id::Nullable{Int}
    user::Nullable{Owner}
    body::Nullable{String}
    state::Nullable{String}
end

function Review(pr::PullRequest, data::Dict)
    rev = json2github(Review, data)
    rev.pr = Nullable(pr)
    rev
end

namefield(rev::Review) = rev.id

@api_default function reviews(api::GitHubAPI, repo, pr::PullRequest; options...)
    path = "/repos/$(name(repo))/pulls/$(name(pr))/reviews"
    results, page_data = gh_get_paged_json(api, path; options...)
    return map(x->Review(pr, x), results), page_data
end

@api_default function comments(api::GitHubAPI, repo, rev::Review; options...)
    path = "/repos/$(name(repo))/pulls/$(name(get(rev.pr)))/reviews/$(name(rev))/comments"
    results, page_data = gh_get_paged_json(api, path; options...)
    return map(Comment, results), page_data
end

@api_default function reply_to(api::GitHubAPI, repo, r::Review, c::Comment, body; options...)
    create_comment(api, repo, get(r.pr), :review; params = Dict(
        :body => body,
        :in_reply_to => get(c.id)
    ), options...)
end

@api_default function dismiss_review(api::GitHubAPI, repo::Repo, r::Review; options...)
    gh_put(api, "/repos/$(name(repo))/pulls/$(name(get(rev.pr)))/reviews/$(name(rev))/dismissals")
end
