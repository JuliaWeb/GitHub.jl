####################
# Default API URIs #
####################

const API_ENDPOINT = HttpCommon.URI("https://api.github.com/")

api_uri(path) = HttpCommon.URI(API_ENDPOINT, path = path)

#######################
# GitHub REST Methods #
#######################

function github_request(request_method, endpoint;
                        auth = AnonymousAuth(), handle_error = true,
                        headers = Dict(), params = Dict())
    authenticate_headers!(headers, auth)
    params = github2json(params)
    api_endpoint = api_uri(endpoint)
    if request_method == Requests.get
        r = request_method(api_endpoint; headers = headers, query = params)
    else
        r = request_method(api_endpoint; headers = headers, json = params)
    end
    handle_error && handle_response_error(r)
    return r
end

gh_get(endpoint = ""; options...) = github_request(Requests.get, endpoint; options...)
gh_post(endpoint = ""; options...) = github_request(Requests.post, endpoint; options...)
gh_put(endpoint = ""; options...) = github_request(Requests.put, endpoint; options...)
gh_delete(endpoint = ""; options...) = github_request(Requests.delete, endpoint; options...)
gh_patch(endpoint = ""; options...) = github_request(Requests.patch, endpoint; options...)

gh_get_json(endpoint = ""; options...) = Requests.json(gh_get(endpoint; options...))
gh_post_json(endpoint = ""; options...) = Requests.json(gh_post(endpoint; options...))
gh_put_json(endpoint = ""; options...) = Requests.json(gh_put(endpoint; options...))
gh_delete_json(endpoint = ""; options...) = Requests.json(gh_delete(endpoint; options...))
gh_patch_json(endpoint = ""; options...) = Requests.json(gh_patch(endpoint; options...))

#################
# Rate Limiting #
#################

rate_limit(; options...) = gh_get_json("/rate_limit"; options...)

##############
# Pagination #
##############

ispaginated(r) = haskey(r.headers, "Link")

isnextlink(str) = contains(str, "rel=\"next\"")
islastlink(str) = contains(str, "rel=\"last\"")

has_next_page(r) = isnextlink(r.headers["Link"])
has_last_page(r) = islastlink(r.headers["Link"])

split_links(r) = split(r.headers["Link"], ',')
get_link(pred, links) = match(r"<.*?>", links[findfirst(pred, links)]).match[2:end-1]

get_page_number(link) = parse(Int, first(match(r"page=(\d+)", link).captures))
get_next_page(r) = get_page_number(get_link(isnextlink, split_links(r)))
get_last_page(r) = get_page_number(get_link(islastlink, split_links(r)))

function request_next_page(r, headers)
    nextlink = get_link(isnextlink, split_links(r))
    return Requests.get(nextlink, headers = headers)
end

function github_paged_request(request_method, endpoint; page_limit = Inf,
                              auth = AnonymousAuth(), handle_error = true,
                              headers = Dict(), params = Dict())
    r = github_request(request_method, endpoint;
                       auth = auth, handle_error = handle_error,
                       headers = headers, params = params)
    results = HttpCommon.Response[r]
    init_page = get(params, "page", 1)
    page_data = Dict{GitHubString, Int}()
    if ispaginated(r)
        last_page = has_last_page(r) ? get_last_page(r) : init_page
        next_page = has_next_page(r) ? get_next_page(r) : -1
        page_count = 1
        while next_page != -1 && page_count < page_limit
            r = request_next_page(r, headers)
            handle_error && handle_response_error(r)
            push!(results, r)
            page_count += 1
            next_page = has_next_page(r) ? get_next_page(r) : -1
        end
        next_page != -1 && (page_data["next"] = next_page)
        page_data["last"] = last_page
        page_data["left"] = last_page - (init_page + page_count - 1)
    else
        page_data["last"] = init_page
        page_data["left"] = 0
    end
    return results, page_data
end

function gh_get_paged_json(endpoint = ""; options...)
    results, page_data = github_paged_request(Requests.get, endpoint; options...)
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
