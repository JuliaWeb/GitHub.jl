


global const API_ENDPOINT = HttpCommon.URI("https://api.github.com/")
global const WEB_ENDPOINT = HttpCommon.URI("https://github.com/")

api_uri(path) = HttpCommon.URI(API_ENDPOINT, path = path)

# Interface -------

set_api_endpoint(endpoint) = (global API_ENDPOINT = endpoint)

set_web_endpoint(endpoint) = (global WEB_ENDPOINT = endpoint)
