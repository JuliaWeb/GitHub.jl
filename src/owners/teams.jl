mutable struct Team <: GitHubType
    name::Union{String, Nothing}
    description::Union{String, Nothing}
    privacy::Union{String, Nothing}
    permission::Union{String, Nothing}
    slug::Union{String, Nothing}
    id::Union{Int, Nothing}
end

namefield(t::Team) = t.id

Team(data::Dict) = json2github(Team, data)

@api_default function members(api::GitHubAPI, team; options...)
    results, page_data = gh_get_paged_json(api, "/teams/$(name(team))/members"; options...)
    return map(Owner, results), page_data
end
