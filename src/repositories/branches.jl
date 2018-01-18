###############
# Branch Type #
###############

mutable struct Branch <: GitHubType
    name       :: ?{String}
    label      :: ?{String}
    ref        :: ?{String}
    sha        :: ?{String}
    commit     :: ?{Commit}
    user       :: ?{Owner}
    repo       :: ?{Repo}
    _links     :: ?{Dict}
    protection :: ?{Dict}
end

Branch(data::Dict) = json2github(Branch, data)
Branch(name::AbstractString) = Branch(Dict("name" => name))

name(branch::Branch) = branch.name === nothing ? branch.ref : branch.name

###############
# API Methods #
###############

@api_default function branches(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/branches"; options...)
    return map(Branch, results), page_data
end

@api_default function branch(api::GitHubAPI, repo, branch_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/branches/$(name(branch_obj))"; options...)
    return Branch(result)
end
