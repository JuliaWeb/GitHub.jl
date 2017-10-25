mutable struct Team <: GitHubType
    name::Nullable{String}
    description::Nullable{String}
    privacy::Nullable{String}
    permission::Nullable{String}
    slug::Nullable{String}
    id::Nullable{Int}
end

namefield(t::Team) = t.id

Team(data::Dict) = json2github(Team, data)

@api_default function members(api::GitHubAPI, team; options...)
    results, page_data = gh_get_paged_json(api, "/teams/$(name(team))/members"; options...)
    return map(Owner, results), page_data
end
