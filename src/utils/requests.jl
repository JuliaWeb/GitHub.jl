const API_ENDPOINT = HttpCommon.URI("https://api.github.com/")

api_uri(path) = HttpCommon.URI(API_ENDPOINT, path = path)

function github_request(request_method, endpoint;
                        auth = AnonymousAuth(), handle_error = true,
                        headers = Dict(), params = Dict())
    authenticate_headers!(headers, auth)
    query = github2json(params)
    r = request_method(api_uri(endpoint); headers = headers, query = query)
    handle_error && handle_response_error(r)
    return r
end

github_get(endpoint = ""; options...) = github_request(Requests.get, endpoint; options...)
github_post(endpoint = ""; options...) = github_request(Requests.post, endpoint; options...)
github_put(endpoint = ""; options...) = github_request(Requests.put, endpoint; options...)
github_delete(endpoint = ""; options...) = github_request(Requests.delete, endpoint; options...)
github_patch(endpoint = ""; options...) = github_request(Requests.patch, endpoint; options...)

github_get_json(endpoint = ""; options...) = Requests.json(github_get(endpoint; options...))
github_post_json(endpoint = ""; options...) = Requests.json(github_post(endpoint; options...))
github_put_json(endpoint = ""; options...) = Requests.json(github_put(endpoint; options...))
github_delete_json(endpoint = ""; options...) = Requests.json(github_delete(endpoint; options...))
github_patch_json(endpoint = ""; options...) = Requests.json(github_patch(endpoint; options...))

function github_paged_get(endpoint=""; auth = AnonymousAuth(), result_limit = -1,
                          headers = Dict(), params = Dict())
    authenticate_headers!(headers, auth)
    query = github2json(params)
    pages = get_pages(api_uri(endpoint), result_limit; headers = headers, query = query)
    return get_items_from_pages(pages)
end

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
