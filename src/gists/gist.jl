@ghdef mutable struct Gist
    url::Union{HTTP.URI, Nothing}
    forks_url::Union{HTTP.URI, Nothing}
    commits_url::Union{HTTP.URI, Nothing}
    id::Union{String, Nothing}
    description::Union{String, Nothing}
    public::Union{Bool, Nothing}
    owner::Union{Owner, Nothing}
    user::Union{Owner, Nothing}
    truncated::Union{Bool, Nothing}
    comments::Union{Int, Nothing}
    comments_url::Union{HTTP.URI, Nothing}
    html_url::Union{HTTP.URI, Nothing}
    git_pull_url::Union{HTTP.URI, Nothing}
    git_push_url::Union{HTTP.URI, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    forks::Union{Vector{Gist}, Nothing}
    files::Union{Dict, Nothing}
    history::Union{Vector{Dict}, Nothing}
end

Gist(id::AbstractString) = Gist(Dict("id" => id))

namefield(gist::Gist) = gist.id

###############
# API Methods #
###############

# creating #
#----------#

@api_default gist(api::GitHubAPI, gist_obj::Gist; options...) = gist(api::GitHubAPI, name(gist_obj); options...)

@api_default function gist(api::GitHubAPI, gist_obj, sha = ""; options...)
    !isempty(sha) && (sha = "/" * sha)
    result = gh_get_json(api, "/gists/$(name(gist_obj))$sha"; options...)
    g = Gist(result)
end

@api_default function gists(api::GitHubAPI, owner; options...)
    results, page_data = gh_get_paged_json(api, "/users/$(name(owner))/gists"; options...)
    map(Gist, results), page_data
end

@api_default function gists(api::GitHubAPI; options...)
    results, page_data = gh_get_paged_json(api, "/gists/public"; options...)
    return map(Gist, results), page_data
end

# modifying #
#-----------#

@api_default create_gist(api::GitHubAPI; options...) = Gist(gh_post_json(api, "/gists"; options...))
@api_default edit_gist(api::GitHubAPI, gist; options...) = Gist(gh_patch_json(api, "/gists/$(name(gist))"; options...))
@api_default delete_gist(api::GitHubAPI, gist; options...) = gh_delete(api, "/gists/$(name(gist))"; options...)

# stars #
#------#

@api_default star_gist(api::GitHubAPI, gist; options...) = gh_put(api, "/gists/$(name(gist))/star"; options...)
@api_default unstar_gist(api::GitHubAPI, gist; options...) = gh_delete(api, "/gists/$(name(gist))/star"; options...)

@api_default function starred_gists(api::GitHubAPI; options...)
    results, page_data = gh_get_paged_json(api, "/gists/starred"; options...)
    return map(Gist, results), page_data
end

# forks #
#-------#

@api_default create_gist_fork(api::GitHubAPI, gist::Gist; options...) = Gist(gh_post_json(api, "/gists/$(name(gist))/forks"; options...))

@api_default function gist_forks(api::GitHubAPI, gist; options...)
    results, page_data = gh_get_paged_json(api, "/gists/$(name(gist))/forks"; options...)
    return map(Gist, results), page_data
end
