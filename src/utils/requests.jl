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
                        headers = Dict(), params = Dict(), page_limit = Inf)
    authenticate_headers!(headers, auth)
    query = github2json(params)
    r = request_method(api_uri(endpoint); headers = headers, query = query)
    handle_error && handle_response_error(r)

    if ispaginated(r)
        results = HttpCommon.Response[r]
        page_count = 1
        while has_next_page(r) && page_count < page_limit
            r = request_next_page(r, headers)
            push!(results, r)
            page_count += 1
        end
        return results
    end

    return r
end

github_get(endpoint = ""; options...) = github_request(Requests.get, endpoint; options...)
github_post(endpoint = ""; options...) = github_request(Requests.post, endpoint; options...)
github_put(endpoint = ""; options...) = github_request(Requests.put, endpoint; options...)
github_delete(endpoint = ""; options...) = github_request(Requests.delete, endpoint; options...)
github_patch(endpoint = ""; options...) = github_request(Requests.patch, endpoint; options...)

github_get_json(endpoint = ""; options...) = jsonify(github_get(endpoint; options...))
github_post_json(endpoint = ""; options...) = jsonify(github_post(endpoint; options...))
github_put_json(endpoint = ""; options...) = jsonify(github_put(endpoint; options...))
github_delete_json(endpoint = ""; options...) = jsonify(github_delete(endpoint; options...))
github_patch_json(endpoint = ""; options...) = jsonify(github_patch(endpoint; options...))

jsonify(r::HttpCommon.Response) = Requests.json(r)
jsonify(arr::Array) = mapreduce(jsonify, vcat, arr)

#################
# Rate Limiting #
#################

rate_limit(; options...) = github_get_json("/rate_limit"; options...)::Dict

##############
# Pagination #
##############

ispaginated(r) = haskey(r.headers, "Link")
isnextlink(s) = contains(s, "rel=\"next\"")
has_next_page(r) = isnextlink(r.headers["Link"])

function request_next_page(r, headers)
    links = split(r.headers["Link"], ',')
    nextlink = match(r"<.*?>", links[findfirst(isnextlink, links)]).match[2:end-1]
    return Requests.get(nextlink, headers = headers)
end

##################
# Error Handling #
##################

function handle_response_error(r::HttpCommon.Response)
    if r.status >= 400
        message, docs_url = "", ""
        try
            data = Requests.json(r)
            message = get(data, "message", "")
            docs_url = get(data, "documentation_url", "")
        end
        error("Error found in GitHub reponse:\n",
              "\tStatus Code: $(r.status)\n",
              "\tMessage: $message\n",
              "\tDocs URL: $docs_url")
    end
end
