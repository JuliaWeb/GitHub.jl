
global const API_ENDPOINT = URI("https://api.github.com/")
global const WEB_ENDPOINT = URI("https://github.com/")


set_api_endpoint(endpoint) = (global API_ENDPOINT = endpoint)

set_web_endpoint(endpoint) = (global WEB_ENDPOINT = endpoint)
