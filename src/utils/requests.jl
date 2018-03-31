##############
# GitHub API #
##############

"""
Represents the API to interact with, either an actual GitHub instance,
or a mock API for testing purposes
"""
abstract type GitHubAPI end

struct GitHubWebAPI <: GitHubAPI
    endpoint::HTTP.URI
end

const DEFAULT_API = GitHubWebAPI(HTTP.URI("https://api.github.com"))

using Base.Meta
"""
For a method taking an API argument, add a new method without the API argument
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
    esc(Expr(:toplevel, func,
        Expr(:function, newcall, Expr(:block,
            :($(call.args[1])(DEFAULT_API, $(argnames...);kwargs...))
        ))))
end

####################
# Default API URIs #
####################

api_uri(api::GitHubWebAPI, path) = merge(api.endpoint, path = path)
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
        r = request_method(merge(api_endpoint, query = params), _headers, redirect = allowredirects, status_exception = false)
    else
        r = request_method(string(api_endpoint), _headers, JSON.json(params), redirect = allowredirects, status_exception = false)
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
        if contains(links[i], relstr)
            return i
        end
    end
    return 0
end

extract_page_url(link) = match(r"<.*?>", link).match[2:end-1]

function github_paged_get(api, endpoint; page_limit = Inf, start_page = "", handle_error = true,
                          headers = Dict(), params = Dict(), options...)
    _headers = convert(Dict{String, String}, headers)
    !haskey(_headers, "User-Agent") && (_headers["User-Agent"] = "GitHub-jl")
    if isempty(start_page)
        r = gh_get(api, endpoint; handle_error = handle_error, headers = _headers, params = params, options...)
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

function gh_get_paged_json(api, endpoint = ""; options...)
    results, page_data = github_paged_get(api, endpoint; options...)
    return mapreduce(r -> JSON.parse(HTTP.payload(r, String)), vcat, results), page_data
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
