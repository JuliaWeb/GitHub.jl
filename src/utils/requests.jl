##############
# GitHub API #
##############

"""
Represents the API to interact with, either an actual GitHub instance,
or a mock API for testing purposes
"""
@compat abstract type GitHubAPI end

immutable GitHubWebAPI <: GitHubAPI
    endpoint::HttpCommon.URI
end

const DEFAULT_API = GitHubWebAPI(HttpCommon.URI("https://api.github.com/"))

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

api_uri(api::GitHubWebAPI, path) = HttpCommon.URI(api.endpoint, path = path)
api_uri(api::GitHubAPI, path) = error("URI retrieval not implemented for this API type")

#######################
# GitHub REST Methods #
#######################

function github_request(api::GitHubAPI, request_method, endpoint;
                        auth = AnonymousAuth(), handle_error = true,
                        headers = Dict(), params = Dict(), allow_redirects = true)
    authenticate_headers!(headers, auth)
    params = github2json(params)
    api_endpoint = api_uri(api, endpoint)
    if request_method == Requests.get
        r = request_method(api_endpoint; headers = headers, query = params, allow_redirects = allow_redirects)
    else
        r = request_method(api_endpoint; headers = headers, json = params, allow_redirects = allow_redirects)
    end
    handle_error && handle_response_error(r)
    return r
end

gh_get(api::GitHubAPI, endpoint = ""; options...) = github_request(api, Requests.get, endpoint; options...)
gh_post(api::GitHubAPI, endpoint = ""; options...) = github_request(api, Requests.post, endpoint; options...)
gh_put(api::GitHubAPI, endpoint = ""; options...) = github_request(api, Requests.put, endpoint; options...)
gh_delete(api::GitHubAPI, endpoint = ""; options...) = github_request(api, Requests.delete, endpoint; options...)
gh_patch(api::GitHubAPI, endpoint = ""; options...) = github_request(api, Requests.patch, endpoint; options...)

gh_get_json(api::GitHubAPI, endpoint = ""; options...) = Requests.json(gh_get(api, endpoint; options...))
gh_post_json(api::GitHubAPI, endpoint = ""; options...) = Requests.json(gh_post(api, endpoint; options...))
gh_put_json(api::GitHubAPI, endpoint = ""; options...) = Requests.json(gh_put(api, endpoint; options...))
gh_delete_json(api::GitHubAPI, endpoint = ""; options...) = Requests.json(gh_delete(api, endpoint; options...))
gh_patch_json(api::GitHubAPI, endpoint = ""; options...) = Requests.json(gh_patch(api, endpoint; options...))

#################
# Rate Limiting #
#################

@api_default rate_limit(api; options...) = gh_get_json(api, "/rate_limit"; options...)

##############
# Pagination #
##############

has_page_links(r) = haskey(r.headers, "Link")
get_page_links(r) = split(r.headers["Link"], ',')

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
    if isempty(start_page)
        r = gh_get(api, endpoint; handle_error = handle_error, headers = headers, params = params, options...)
    else
        @assert isempty(params) "`start_page` kwarg is incompatible with `params` kwarg"
        r = Requests.get(start_page, headers = headers)
    end
    results = HttpCommon.Response[r]
    page_data = Dict{String, String}()
    if has_page_links(r)
        page_count = 1
        while page_count < page_limit
            links = get_page_links(r)
            next_index = find_page_link(links, "next")
            next_index == 0 && break
            r = Requests.get(extract_page_url(links[next_index]), headers = headers)
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
    return mapreduce(Requests.json, vcat, results), page_data
end

##################
# Error Handling #
##################

function handle_response_error(r::HttpCommon.Response)
    if r.status >= 400
        message, docs_url, errors = "", "", ""
        try
            data = Requests.json(r)
            message = get(data, "message", "")
            docs_url = get(data, "documentation_url", "")
            errors = get(data, "errors", "")
        end
        error("Error found in GitHub reponse:\n",
              "\tStatus Code: $(r.status)\n",
              "\tMessage: $message\n",
              "\tDocs URL: $docs_url\n",
              "\tErrors: $errors")
    end
end
