##############
# GitHub API #
##############

"""
Represents the API to interact with, either an actual GitHub instance,
or a mock API for testing purposes
"""
abstract type GitHubAPI end

struct GitHubWebAPI <: GitHubAPI
    endpoint::URIs.URI
end

const DEFAULT_API = GitHubWebAPI(URIs.URI("https://api.github.com"))

using Base.Meta

"""
    @api_default function f(api, args...)
    ...
    end

For a method taking an `api` argument, add a new method without the `api` argument
that just calls the method with DEFAULT_API.
"""
macro api_default(func)
    call = func.args[1]
    has_kwargs = isexpr(call.args[2], :parameters)
    newcall = Expr(:call, call.args[1], (has_kwargs ?
        [Expr(:parameters, Expr(:..., :kwargs)); call.args[4:end]] : call.args[3:end])...)
    argnames = map(has_kwargs ? call.args[4:end] : call.args[3:end]) do expr
        isexpr(expr, :kw) && (expr = expr.args[1])
        isexpr(expr, Symbol("::")) && return expr.args[1]
        @assert isa(expr, Symbol)
        return expr
    end
    esc(Expr(:toplevel, :(Base.@__doc__ $func),
        Expr(:function, newcall, Expr(:block,
            :($(call.args[1])(DEFAULT_API, $(argnames...);kwargs...))
        ))))
end

####################
# Default API URIs #
####################

function api_uri(api::GitHubWebAPI, path)
    # do not allow path traversal
    if occursin(r"(^|/)\.\.(\/|$)", path)
        throw(ArgumentError("Invalid API path: '$path'"))
    end
    return URIs.URI(api.endpoint, path = api.endpoint.path * path)
end
api_uri(api::GitHubAPI, path) = error("URI retrieval not implemented for this API type")

#######################
# GitHub REST Methods #
#######################

function github_request(api::GitHubAPI, request_method, endpoint;
                        auth = AnonymousAuth(), handle_error = true,
                        headers = Dict(), params = Dict(), allowredirects = true)
    authenticate_headers!(headers, auth)
    params = github2json(params)
    api_endpoint = api_uri(api, endpoint)
    _headers = convert(Dict{String, String}, headers)
    !haskey(_headers, "User-Agent") && (_headers["User-Agent"] = "GitHub-jl")
    if request_method == HTTP.get
        r = request_method(URIs.URI(api_endpoint, query = params), _headers, redirect = allowredirects, status_exception = false, idle_timeout=20)
    else
        r = request_method(string(api_endpoint), _headers, JSON.json(params), redirect = allowredirects, status_exception = false, idle_timeout=20)
    end
    handle_error && handle_response_error(r)
    return r
end

gh_get(api::GitHubAPI, endpoint = ""; options...) = github_request(api, HTTP.get, endpoint; options...)
gh_post(api::GitHubAPI, endpoint = ""; options...) = github_request(api, HTTP.post, endpoint; options...)
gh_put(api::GitHubAPI, endpoint = ""; options...) = github_request(api, HTTP.put, endpoint; options...)
gh_delete(api::GitHubAPI, endpoint = ""; options...) = github_request(api, HTTP.delete, endpoint; options...)
gh_patch(api::GitHubAPI, endpoint = ""; options...) = github_request(api, HTTP.patch, endpoint; options...)

gh_get_json(api::GitHubAPI, endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_get(api, endpoint; options...), String))
gh_post_json(api::GitHubAPI, endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_post(api, endpoint; options...), String))
gh_put_json(api::GitHubAPI, endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_put(api, endpoint; options...), String))
gh_delete_json(api::GitHubAPI, endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_delete(api, endpoint; options...), String))
gh_patch_json(api::GitHubAPI, endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_patch(api, endpoint; options...), String))

#################
# Rate Limiting #
#################

@api_default rate_limit(api::GitHubAPI; options...) = gh_get_json(api, "/rate_limit"; options...)

##############
# Pagination #
##############

has_page_links(r) = HTTP.hasheader(r, "Link")
get_page_links(r) = split(HTTP.header(r, "Link",), ",")

function find_page_link(links, rel)
    relstr = "rel=\"$(rel)\""
    for i in 1:length(links)
        if occursin(relstr, links[i])
            return i
        end
    end
    return 0
end

extract_page_url(link) = match(r"<.*?>", link).match[2:end-1]

function github_paged_get(api, endpoint; page_limit = Inf, start_page = "", handle_error = true,
                          auth = AnonymousAuth(), headers = Dict(), params = Dict(), options...)
    authenticate_headers!(headers, auth)
    _headers = convert(Dict{String, String}, headers)
    !haskey(_headers, "User-Agent") && (_headers["User-Agent"] = "GitHub-jl")
    if isempty(start_page)
        r = gh_get(api, endpoint; handle_error = handle_error, headers = _headers, params = params, auth=auth, options...)
    else
        @assert isempty(params) "`start_page` kwarg is incompatible with `params` kwarg"
        r = HTTP.get(start_page, headers = _headers)
    end
    results = HTTP.Response[r]
    page_data = Dict{String, String}()
    if has_page_links(r)
        page_count = 1
        while page_count < page_limit
            links = get_page_links(r)
            next_index = find_page_link(links, "next")
            next_index == 0 && break
            r = HTTP.get(extract_page_url(links[next_index]), headers = _headers)
            handle_error && handle_response_error(r)
            push!(results, r)
            page_count += 1
        end
        links = get_page_links(r)
        for page in ("next", "last", "first", "prev")
            page_index = find_page_link(links, page)
            if page_index != 0
                page_data[page] = extract_page_url(links[page_index])
            end
        end
    end
    return results, page_data
end

# for APIs which return just a list
function gh_get_paged_json(api, endpoint = ""; options...)
    results, page_data = github_paged_get(api, endpoint; options...)
    parsed_results = mapreduce(r -> JSON.parse(HTTP.payload(r, String)), vcat, results)
    if !(isa(parsed_results, Vector))
        parsed_results = [parsed_results]
    end
    return parsed_results, page_data
end

# for APIs which return a Dict(key => list, "total_count" => count)
function gh_get_paged_json(api, endpoint, key; options...)
    results, page_data = github_paged_get(api, endpoint; options...)
    local total_count
    list = mapreduce(vcat, results) do r
        dict = JSON.parse(HTTP.payload(r, String))
        total_count = dict["total_count"]
        dict[key]
    end
    list, page_data, total_count
end

##################
# Error Handling #
##################

function handle_response_error(r::HTTP.Response)
    if r.status >= 400
        message, docs_url, errors = "", "", ""
        body = HTTP.payload(r, String)
        try
            data = JSON.parse(body)
            message = get(data, "message", "")
            docs_url = get(data, "documentation_url", "")
            errors = get(data, "errors", "")
        catch
        end
        error("Error found in GitHub reponse:\n",
              "\tStatus Code: $(r.status)\n",
              ((isempty(message) && isempty(errors)) ?
               ("\tBody: $body",) :
               ("\tMessage: $message\n",
                "\tDocs URL: $docs_url\n",
                "\tErrors: $errors"))...)
    end
end

###############
# Validations #
###############

check_disallowed_name_pattern(v) = v
function check_disallowed_name_pattern(str::AbstractString)
    # do not allow path traversal in names
    if occursin(r"\.\.", str)
        throw(ArgumentError("name cannot contain path traversal"))
    end
    # do not allow new lines or carriage returns or any other whitespace in names
    if occursin(r"\s", str)
        throw(ArgumentError("name cannot contain line breaks"))
    end

    return str
end