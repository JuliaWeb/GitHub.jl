@ghdef mutable struct Team
    name::Union{String, Nothing}
    description::Union{String, Nothing}
    privacy::Union{String, Nothing}
    permission::Union{String, Nothing}
    slug::Union{String, Nothing}
    id::Union{Int, Nothing}
end

namefield(t::Team) = t.id


@api_default function members(api::GitHubAPI, team; options...)
    results, page_data = gh_get_paged_json(api, "/teams/$(name(team))/members"; options...)
    return map(Owner, results), page_data
end

@api_default function repos(api::GitHubAPI, owner::Owner, team::Team; options...)
    results, page_data = gh_get_paged_json(api, "/orgs/$(owner.login)/teams/$(team.slug)/repos"; options...)
    return map(Repo, results), page_data
end
