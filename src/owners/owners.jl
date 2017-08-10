##############
# Owner Type #
##############

type Owner <: GitHubType
    typ::Nullable{String}
    email::Nullable{String}
    name::Nullable{String}
    login::Nullable{String}
    bio::Nullable{String}
    company::Nullable{String}
    location::Nullable{String}
    gravatar_id::Nullable{String}
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

@api_default owner(api::GitHubAPI, owner_obj::Owner; options...) = owner(api, name(owner_obj), isorg(owner_obj); options...)

@api_default function owner(api::GitHubAPI, owner_obj, isorg = false; options...)
    result = gh_get_json(api, "/$(typprefix(isorg))/$(name(owner_obj))"; options...)
    return Owner(result)
end

@api_default function users(api::GitHubAPI; options...)
    results, page_data = gh_get_paged_json(api, "/users"; options...)
    return map(Owner, results), page_data
end

@api_default function check_membership(api::GitHubAPI, org, user; public_only = false, options...)
    scope = public_only ? "public_members" : "members"
    resp = gh_get(api, "/orgs/$(name(org))/$scope/$(name(user))"; handle_error = false, allow_redirects = false,  options...)
    if resp.status == 204
        return true
    elseif resp.status == 404
        return false
    elseif resp.status == 302
        # For convenience, still check public membership. Otherwise, we don't know, so error
        @assert !public_only
        is_public_member = check_membership(org, user; public_only = true, options...)
        is_public_member && return true
        error("Enquiring about an Organization to which you do not have access.\n"*
              "Set `public_only=true` or provide authentication.")
    else
        handle_response_error(resp)
    end
end

@api_default function orgs(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(owner))/orgs"; options...)
    return map(Owner, results), page_data
end

@api_default function followers(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(owner))/followers"; options...)
    return map(Owner, results), page_data
end

@api_default function following(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(owner))/following"; options...)
    return map(Owner, results), page_data
end

@api_default function pubkeys(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(owner))/keys"; options...)
    output = Dict{Int,String}([(key["id"], key["key"]) for key in results])
    return output, page_data
end

repos(api::GitHubAPI, owner::Owner; options...) = repos(api, name(owner), isorg(owner); options...)

@api_default function repos(api::GitHubAPI, owner, isorg = false; options...)
    results, page_data = gh_get_paged_json(api, "/$(typprefix(isorg))/$(name(owner))/repos"; options...)
    return map(Repo, results), page_data
end

@api_default function teams(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/orgs/$(name(owner))/teams"; options...)
    return map(Team, results), page_data
end


