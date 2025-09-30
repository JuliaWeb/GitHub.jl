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

const MUTATION_LOCK = ReentrantLock()
const LAST_MUTATION_TIMESTAMPS = Dict{UInt64, Float64}()

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

function safe_tryparse(args...)
    try
        return tryparse(args...)
    catch
        nothing
    end
end

"""
    github_retry_decision(method::String, resp::Union{HTTP.Response, Nothing}, ex::Union{Exception, Nothing}, exponential_delay::Float64; verbose::Bool=true) -> (should_retry::Bool, sleep_seconds::Float64)

Analyzes a GitHub API response/exception to determine if a request should be retried and how long to wait.
Uses HTTP.jl's retry logic as a foundation, then adds GitHub-specific rate limiting handling.
This function does NOT perform any sleeping - it only returns the decision and timing information.
Logs retry decisions with detailed rate limit information when retries occur (if verbose=true).

# Arguments
- `method`: HTTP method string (e.g., "GET", "POST")
- `resp`: HTTP response object (if a response was received), or `nothing`
- `ex`: Exception that occurred (if any), or `nothing`
- `exponential_delay`: The delay from ExponentialBackOff iterator
- `verbose`: Whether to log retry decisions (default: true)

# Returns
A tuple `(should_retry, sleep_seconds)` where:
- `should_retry`: `true` if the request should be retried, `false` otherwise
- `sleep_seconds`: Number of seconds to sleep before retry (0 if no sleep needed)

# Retry Logic
1. First uses HTTP.jl's standard retry logic (`isrecoverable` + `isidempotent`)
2. Then adds GitHub-specific rate limiting:
   - **Primary rate limit**: `x-ratelimit-remaining: 0` → wait until `x-ratelimit-reset` time
   - **Secondary rate limit**: Has `retry-after` header OR error message indicates secondary →
     - If `retry-after` present: use that delay
     - If `x-ratelimit-remaining: 0`: wait until reset time
     - Otherwise: wait at least 1 minute, then use exponential backoff

This follows the [documentation from GitHub](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#exceeding-the-rate-limit) as of 2025.
"""
function github_retry_decision(method::String, resp::Union{HTTP.Response, Nothing}, ex::Union{Exception, Nothing}, exponential_delay::Float64; verbose::Bool=true)
    # If we have a response, process it first (takes precedence over exceptions)
    if resp !== nothing
        status = resp.status

        # Don't retry successful responses
        if status < 400
            return (false, 0.0)
        end
    else
        # No response - check if we have a recoverable exception
        if ex !== nothing
            # If there's an exception, check if it's recoverable and if the method is idempotent
            if HTTP.RetryRequest.isrecoverable(ex) && HTTP.RetryRequest.isidempotent(method)
                verbose && @info "GitHub API exception, retrying in $(round(exponential_delay, digits=1))s" method=method exception=ex
                return (true, exponential_delay)
            end
        end
        # No response and no retryable exception
        return (false, 0.0)
    end

    # At this point we have a response with status >= 400
    # First let us see if we want to retry it.

    # Note: `String` takes ownership / removes the body, so we make a copy
    body = String(copy(resp.body))
    is_primary_rate_limit = occursin("primary rate limit", lowercase(body)) && status in (403, 429)
    is_secondary_rate_limit = occursin("secondary rate limit", lowercase(body)) && status in (403, 429)

    # `other_retry` is `HTTP.RetryRequest.retryable(status)` minus 403,
    # since if it's not a rate-limit, we don't want to retry 403s.
    other_retry = status in (408, 409, 429, 500, 502, 503, 504, 599)

    do_retry = HTTP.RetryRequest.isidempotent(method) && (is_primary_rate_limit || is_secondary_rate_limit || other_retry)

    if !do_retry
        return (false, 0.0)
    end

    # Now we know we want to retry. We need to decide how long to wait.

    # Get all rate limit headers
    limit = HTTP.header(resp, "x-ratelimit-limit", "")
    remaining = HTTP.header(resp, "x-ratelimit-remaining", "")
    used = HTTP.header(resp, "x-ratelimit-used", "")
    reset_time = HTTP.header(resp, "x-ratelimit-reset", "")
    resource = HTTP.header(resp, "x-ratelimit-resource", "")
    retry_after = HTTP.header(resp, "retry-after", "")

    msg = if is_primary_rate_limit
        "GitHub API primary rate limit reached"
    elseif is_secondary_rate_limit
        "GitHub API secondary rate limit reached"
    else
        "GitHub API returned $status"
    end

    # If retry-after header is present, respect it
    delay_seconds = safe_tryparse(Float64, retry_after)
    if delay_seconds !== nothing
        delay_seconds = parse(Float64, retry_after)
        verbose && @info "$msg, retrying in $(round(delay_seconds, digits=1))s" method=method status=status limit=limit remaining=remaining used=used reset=reset_time resource=resource retry_after=retry_after
        return (true, delay_seconds)
    end

    # If x-ratelimit-remaining is 0, wait until reset time
    reset_timestamp = safe_tryparse(Float64, reset_time)
    if remaining == "0" && reset_timestamp !== nothing
        current_time = time()
        if reset_timestamp > current_time
            delay_seconds = reset_timestamp - current_time + 1.0
            verbose && @info "$msg, retrying in $(round(delay_seconds, digits=1))s" method=method status=status limit=limit remaining=remaining used=used reset=reset_time resource=resource retry_after=retry_after
            return (true, delay_seconds)
        end
    end

    # If secondary rate limit hit without headers to guide us,
    # make sure we wait at least a minute
    delay_seconds = is_secondary_rate_limit ? max(60.0, exponential_delay) :  exponential_delay

    # Fall back to exponential backoff
    verbose && @info "$msg, retrying in $(round(delay_seconds, digits=1))s" method=method status=status

    return (true, delay_seconds)
end

function wait_for_mutation_delay(auth_hash; sleep_fn=sleep, time_fn=time)
    while true
        now = time_fn()
        local wait_time
        # Checking & setting must be atomic to prevent races, so we use a lock
        @lock MUTATION_LOCK begin
            last_ts = get(LAST_MUTATION_TIMESTAMPS, auth_hash, 0.0)
            wait_time = last_ts == 0.0 ? 0.0 : (last_ts + 1.0 - now)
            if wait_time <= 0 # good to go
                LAST_MUTATION_TIMESTAMPS[auth_hash] = now
                return nothing
            end
        end
        sleep_fn(wait_time)
    end
end

struct RetryDelayException <: Exception
    msg::String
end
Base.showerror(io::IO, e::RetryDelayException) = print(io, e.msg)

"""
    with_retries(f; method::AbstractString="GET", max_retries::Int=5, verbose::Bool=true, sleep_fn=sleep, max_sleep_seconds::Real = 20*60)

Generic retry wrapper that executes function `f()` with GitHub-specific retry logic.

# Arguments
- `f`: Function to execute (should return HTTP.Response or throw exception)
- `method`: HTTP method for retry decision logic (default: "GET")
- `max_retries`: Maximum number of retry attempts (default: 5)
- `verbose`: Whether to log retry decisions (default: true)
- `sleep_fn`: Function to call for sleeping between retries (default: sleep). For testing, can be replaced with a custom function.
- `max_sleep_seconds::Real`: maximum number of seconds to sleep when delaying before retrying. If the intended retry delay exceeds `max_sleep_seconds` an exception is thrown instead. This parameter defaults to 20*60 (20 minutes).

# Returns
Returns the result of `f()` if successful, or re-throws the final exception if all retries fail.

# Example
```julia
result = with_retries(method="GET", verbose=false) do
    HTTP.get("https://api.github.com/user", headers)
end
```
"""
function with_retries(f; method::AbstractString="GET", max_retries::Int=5, verbose::Bool=true, sleep_fn=sleep, max_sleep_seconds::Real = 60*20, respect_mutation_delay=true, auth_hash)
    backoff = Base.ExponentialBackOff(n = max_retries+1)
    method_upper = uppercase(method)
    requires_mutation_throttle = respect_mutation_delay && method_upper in ("POST", "PATCH", "PUT", "DELETE")
    for (attempt, exponential_delay) in enumerate(backoff)
        last_try = attempt > max_retries
        if requires_mutation_throttle
            wait_for_mutation_delay(auth_hash; sleep_fn)
        end
        local r, ex
        try
            r = f()
            ex = nothing
            if last_try
                return r
            end
        catch e
            r = nothing
            ex = e
            if last_try
                rethrow()
            end
        end

        # Check if we should retry based on this attempt
        should_retry, sleep_seconds = github_retry_decision(method, r, ex, exponential_delay; verbose)

        if !should_retry
            if ex !== nothing
                throw(ex)
            else
                return r
            end
        end
        if sleep_seconds > max_sleep_seconds
            throw(RetryDelayException("Retry delay $(sleep_seconds) exceeds configured maximum ($(max_sleep_seconds) seconds)"))
        end
        if sleep_seconds > 0
            sleep_fn(sleep_seconds)
        end
    end
end

function github_request(api::GitHubAPI, request_method::String, endpoint;
                        auth = AnonymousAuth(), handle_error = true,
                        headers = Dict(), params = Dict(), allowredirects = true,
                        max_retries = 5, verbose = true, max_sleep_seconds = 20*60, respect_mutation_delay = true)
    authenticate_headers!(headers, auth)
    params = github2json(params)
    api_endpoint = api_uri(api, endpoint)
    _headers = convert(Dict{String, String}, headers)
    !haskey(_headers, "User-Agent") && (_headers["User-Agent"] = "GitHub-jl")
    auth_hash = get_auth_hash(auth)
    r = with_retries(; method = request_method, max_retries, verbose, max_sleep_seconds, respect_mutation_delay, auth_hash) do
        if request_method == "GET"
            return HTTP.request(request_method, URIs.URI(api_endpoint, query = params), _headers;
                               redirect = allowredirects, status_exception = false,
                               idle_timeout = 20, retry = false)
        else
            return HTTP.request(request_method, string(api_endpoint), _headers, JSON.json(params);
                               redirect = allowredirects, status_exception = false,
                               idle_timeout = 20, retry = false)
        end
    end

    handle_error && handle_response_error(r)
    return r
end

gh_get(api::GitHubAPI, endpoint = ""; options...) = github_request(api, "GET", endpoint; options...)
gh_post(api::GitHubAPI, endpoint = ""; options...) = github_request(api, "POST", endpoint; options...)
gh_put(api::GitHubAPI, endpoint = ""; options...) = github_request(api, "PUT", endpoint; options...)
gh_delete(api::GitHubAPI, endpoint = ""; options...) = github_request(api, "DELETE", endpoint; options...)
gh_patch(api::GitHubAPI, endpoint = ""; options...) = github_request(api, "PATCH", endpoint; options...)

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
                          auth = AnonymousAuth(), headers = Dict(), params = Dict(), max_retries = 5, verbose = true, max_sleep_seconds = 20*60, respect_mutation_delay = true, options...)
    authenticate_headers!(headers, auth)
    _headers = convert(Dict{String, String}, headers)
    !haskey(_headers, "User-Agent") && (_headers["User-Agent"] = "GitHub-jl")

    auth_hash = get_auth_hash(auth)
    # Helper function to make a get request with retries
    function make_request_with_retries(url, headers)
        return with_retries(; method = "GET", max_retries, verbose, max_sleep_seconds, respect_mutation_delay, auth_hash) do
            HTTP.request("GET", url, headers; status_exception = false, retry = false)
        end
    end

    if isempty(start_page)
        r = gh_get(api, endpoint; handle_error, headers = _headers, params, auth, max_retries, verbose, max_sleep_seconds, respect_mutation_delay, options...)
    else
        @assert isempty(params) "`start_page` kwarg is incompatible with `params` kwarg"
        r = make_request_with_retries(start_page, _headers)
    end
    results = HTTP.Response[r]
    page_data = Dict{String, String}()
    if has_page_links(r)
        page_count = 1
        while page_count < page_limit
            links = get_page_links(r)
            next_index = find_page_link(links, "next")
            next_index == 0 && break
            r = make_request_with_retries(extract_page_url(links[next_index]), _headers)
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
        error("Error found in GitHub response:\n",
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
