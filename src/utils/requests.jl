const API_ENDPOINT = HttpCommon.URI("https://api.github.com/")

api_uri(path) = HttpCommon.URI(API_ENDPOINT, path = path)

function github_request(request_method, endpoint; auth = AnonymousAuth(), headers = Dict(), options...)
    authenticate_headers!(headers, auth)
    r = request_method(api_uri(endpoint); headers = headers, options...)
    handle_error(r)
    return Requests.json(r)
end

github_get(endpoint; options...) = github_request(Requests.get, endpoint; options...)
github_post(endpoint; options...) = github_request(Requests.post, endpoint; options...)
github_put(endpoint; options...) = github_request(Requests.put, endpoint; options...)

function github_paged_get(endpoint; auth = AnonymousAuth(), headers = Dict(), result_limit = -1, options...)
    authenticate_headers!(headers, auth)
    pages = get_pages(api_uri(endpoint), result_limit; headers = headers, options...)
    return get_items_from_pages(pages)
end
