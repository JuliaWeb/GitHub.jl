##############
# Owner Type #
##############

@ghdef mutable struct Owner
    typ::Union{String, Nothing}
    email::Union{String, Nothing}
    name::Union{String, Nothing}
    login::Union{String, Nothing}
    bio::Union{String, Nothing}
    company::Union{String, Nothing}
    location::Union{String, Nothing}
    gravatar_id::Union{String, Nothing}
    id::Union{Int, Nothing}
    public_repos::Union{Int, Nothing}
    owned_private_repos::Union{Int, Nothing}
    total_private_repos::Union{Int, Nothing}
    public_gists::Union{Int, Nothing}
    private_gists::Union{Int, Nothing}
    followers::Union{Int, Nothing}
    following::Union{Int, Nothing}
    collaborators::Union{Int, Nothing}
    blog::Union{HTTP.URI, Nothing}
    url::Union{HTTP.URI, Nothing}
    html_url::Union{HTTP.URI, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    date::Union{Dates.DateTime, Nothing}
    hireable::Union{Bool, Nothing}
    site_admin::Union{Bool, Nothing}
end

Owner(login::AbstractString, isorg = false) = Owner(Dict("login" => login, "type" => isorg ? "Organization" : "User"))

namefield(owner::Owner) = owner.login

typprefix(isorg) = isorg ? "orgs" : "users"

#############
# Owner API #
#############

isorg(owner::Owner) = something(owner.typ, "") == "Organization"

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
    resp = gh_get(api, "/orgs/$(name(org))/$scope/$(name(user))"; handle_error = false, allowredirects = false, options...)
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
    Base.depwarn("`pubkeys` is deprecated in favor of `sshkeys`, " *
        "which return a vector of keys, instead of a Dict from key-id to key.", :pubkeys)
    results, page_data = sshkeys(api, owner; options...)
    output = Dict{Int,String}([(key["id"], key["key"]) for key in results])
    return output, page_data
end

@api_default function sshkeys(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(owner))/keys"; options...)
    output = convert(Vector{Dict{String,Any}}, results)
    return output, page_data
end

@api_default function gpgkeys(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(owner))/gpg_keys"; options...)
    output = convert(Vector{Dict{String,Any}}, results)
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


