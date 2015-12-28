###############
# Branch Type #
###############

type Branch <: GitHubType
    name::Nullable{GitHubString}
    label::Nullable{GitHubString}
    ref::Nullable{GitHubString}
    sha::Nullable{GitHubString}
    commit::Nullable{Commit}
    user::Nullable{Owner}
    repo::Nullable{Repo}
    _links::Nullable{Dict}
    protection::Nullable{Dict}
end

Branch(data::Dict) = json2github(Branch, data)
Branch(name::AbstractString) = Branch(Dict("name" => name))

namefield(branch::Branch) = isnull(branch.name) ? branch.ref : branch.name

###############
# API Methods #
###############

function branches(repo; options...)
    results, page_data = gh_get_paged_json("/repos/$(name(repo))/branches"; options...)
    return map(Branch, results), page_data
end

function branch(repo, branch_obj; options...)
    result = gh_get_json("/repos/$(name(repo))/branches/$(name(branch_obj))"; options...)
    return Branch(result)
end
