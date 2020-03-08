###############
# Branch Type #
###############

@ghdef mutable struct Branch
    name::Union{String, Nothing}
    label::Union{String, Nothing}
    ref::Union{String, Nothing}
    sha::Union{String, Nothing}
    commit::Union{Commit, Nothing}
    user::Union{Owner, Nothing}
    repo::Union{Repo, Nothing}
    _links::Union{Dict, Nothing}
    protection::Union{Dict, Nothing}
end

Branch(name::AbstractString) = Branch(Dict("name" => name))

namefield(branch::Branch) = (branch.name === nothing) ? branch.ref : branch.name

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
