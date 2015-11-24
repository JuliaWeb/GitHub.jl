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

urifield(owner::Owner) = owner.login

#############
# Owner API #
#############

typealias ValidOwner Union{AbstractString, Owner}

user(obj::ValidOwner; options...) = Owner(github_get_json("/users/$(urirepr(obj))"; options...))
org(obj::ValidOwner; options...) = Owner(github_get_json("/orgs/$(urirepr(obj))"; options...))
orgs(obj::ValidOwner; options...) = map(Owner, github_paged_get("/users/$(urirepr(obj))/orgs"; options...))
followers(obj::ValidOwner; options...) = map(Owner, github_paged_get("/users/$(urirepr(obj))/followers"; options...))
following(obj::ValidOwner; options...) = map(Owner, github_paged_get("/users/$(urirepr(obj))/following"; options...))
