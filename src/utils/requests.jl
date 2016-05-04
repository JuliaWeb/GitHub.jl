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

function github_paged_get(endpoint; page_limit = Inf, start_page = "", handle_error = true,
                          headers = Dict(), params = Dict(), options...)
    if isempty(start_page)
        r = gh_get(endpoint; handle_error = handle_error, headers = headers, params = params, options...)
    else
        @assert isempty(params) "`start_page` kwarg is incompatible with `params` kwarg"
        r = Requests.get(start_page, headers = headers)
    end
    results = HttpCommon.Response[r]
    page_data = Dict{GitHubString, GitHubString}()
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

function gh_get_paged_json(endpoint = ""; options...)
    results, page_data = github_paged_get(endpoint; options...)
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
