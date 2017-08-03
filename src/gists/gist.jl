type Gist <: GitHubType
    url::Nullable{HttpCommon.URI}
    forks_url::Nullable{HttpCommon.URI}
    commits_url::Nullable{HttpCommon.URI}
    id::Nullable{String}
    description::Nullable{String}
    public::Nullable{Bool}
    owner::Nullable{Owner}
    user::Nullable{Owner}
    truncated::Nullable{Bool}
    comments::Nullable{Int}
    comments_url::Nullable{HttpCommon.URI}
    html_url::Nullable{HttpCommon.URI}
    git_pull_url::Nullable{HttpCommon.URI}
    git_push_url::Nullable{HttpCommon.URI}
    created_at::Nullable{Dates.DateTime}
    updated_at::Nullable{Dates.DateTime}
    forks::Nullable{Vector{Gist}}
    files::Nullable{Dict}
    history::Nullable{Vector{Dict}}
end

Gist(data::Dict) = json2github(Gist, data)
Gist(id::AbstractString) = Gist(Dict("id" => id))

namefield(gist::Gist) = gist.id

###############
# API Methods #
###############

# creating #
#----------#

gist(gist_obj::Gist; options...) = gist(name(gist_obj); options...)

function gist(gist_obj, sha = ""; options...)
    !isempty(sha) && (sha = "/" * sha)
    result = gh_get_json("/gists/$(name(gist_obj))$sha"; options...)
    g = Gist(result)
end

function gists(owner; options...)
    results, page_data = gh_get_paged_json("/users/$(name(owner))/gists"; options...)
    map(Gist, results), page_data
end

function gists(; options...) 
    results, page_data = gh_get_paged_json("/gists/public"; options...)
    return map(Gist, results), page_data
end

# modifying #
#-----------#

create_gist(; options...) = Gist(gh_post_json("/gists"; options...))
edit_gist(gist; options...) = Gist(gh_patch_json("/gists/$(name(gist))"; options...))
delete_gist(gist; options...) = gh_delete("/gists/$(name(gist))"; options...)

# stars #
#------#

star_gist(gist; options...) = gh_put("/gists/$(name(gist))/star"; options...)
unstar_gist(gist; options...) = gh_delete("/gists/$(name(gist))/star"; options...)

function starred_gists(; options...)
    results, page_data = gh_get_paged_json("/gists/starred"; options...)
    return map(Gist, results), page_data
end

# forks #
#-------#

create_gist_fork(gist::Gist; options...) = Gist(gh_post_json("/gists/$(name(gist))/forks"; options...))

function gist_forks(gist; options...)
    results, page_data = gh_get_paged_json("/gists/$(name(gist))/forks"; options...)
    return map(Gist, results), page_data
end
