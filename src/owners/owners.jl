##############
# Owner Type #
##############

type Owner <: GitHubType
    typ::Nullable{GitHubString}
    email::Nullable{GitHubString}
    name::Nullable{GitHubString}
    login::Nullable{GitHubString}
    bio::Nullable{GitHubString}
    company::Nullable{GitHubString}
    location::Nullable{GitHubString}
    gravatar_id::Nullable{GitHubString}
    id::Nullable{Int}
    public_repos::Nullable{Int}
    owned_private_repos::Nullable{Int}
    total_private_repos::Nullable{Int}
    public_gists::Nullable{Int}
    private_gists::Nullable{Int}
    followers::Nullable{Int}
    following::Nullable{Int}
    collaborators::Nullable{Int}
    blog::Nullable{HttpCommon.URI}
    url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    updated_at::Nullable{Dates.DateTime}
    created_at::Nullable{Dates.DateTime}
    date::Nullable{Dates.DateTime}
    hireable::Nullable{Bool}
    site_admin::Nullable{Bool}
end

Owner(data::Dict) = json2github(Owner, data)
Owner(login::AbstractString, isorg = false) = Owner(Dict("login" => login, "typ" => isorg ? "User" : "Organization"))

namefield(owner::Owner) = owner.login

typprefix(isorg) = isorg ? "orgs" : "users"

#############
# Owner API #
#############

isorg(owner::Owner) = get(owner.typ, "") == "Organization"

owner(owner_obj::Owner; options...) = owner(name(owner_obj), isorg(owner_obj); options...)
owner(owner_obj, isorg = false; options...) = Owner(github_get_json("/$(typprefix(isorg))/$(name(owner_obj))"; options...))

orgs(owner; options...) = map(Owner, github_get_json("/users/$(name(owner))/orgs"; options...))

followers(owner; options...) = map(Owner, github_get_json("/users/$(name(owner))/followers"; options...))
following(owner; options...) = map(Owner, github_get_json("/users/$(name(owner))/following"; options...))

repos(owner::Owner; options...) = repos(name(owner), isorg(owner); options...)
repos(owner, isorg = false; options...) = map(Repo, github_get_json("/$(typprefix(isorg))/$(name(owner))/repos"; options...))
