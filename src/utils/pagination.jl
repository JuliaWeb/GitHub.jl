# Pagination Helper Functions

# Parses a Link header into the links it represents
function parse_link_header(s::AbstractString)
    results = Dict{AbstractString, HttpCommon.URI}()

    # <url>; rel="name", <url2>; rel="name2", ...
    for m in eachmatch(r"<([^>]+)>; rel=\"(\w+)\",? ?", s)
        results[m.captures[2]] = HttpCommon.URI(m.captures[1])
    end

    return results
end

# Given a HttpCommon.URI, fetches it
# Returns the response and the next link, if any.
function next_page(next_link::HttpCommon.URI, headers::Dict{AbstractString, AbstractString})
    r = Requests.get(next_link; headers = headers)
    handle_error(r)

    links = parse_link_header(r.headers["Link"])
    if haskey(links, "next")
        return (r, links["next"])
    end

    return (r, nothing)
end

# To make pages iterable
type Pager
    initial_link::HttpCommon.URI
    headers::Dict{AbstractString, AbstractString}
end

Base.start(p::Pager) = p.initial_link
Base.next(p::Pager, l::HttpCommon.URI) = next_page(l, p.headers)
Base.done(p::Pager, l::HttpCommon.URI) = false
Base.done(p::Pager, l::Void) = true

# Designed to be called by functions that want paginated access
# u and all the keyword argument comprise the call you would have make to Requests.get
# result_limit is the desired number of results; the default (-1) indicates all results
# per_page is the number of results to expect per page; default is 30, GitHub's default
# Returns an Array of Responses (1 per page)
function _get_pages(r::HttpCommon.Response, result_limit::Int = -1, per_page::Int = 30; headers = Dict(), options...)
    pages = [r]
    links = haskey(r.headers, "Link") ? parse_link_header(r.headers["Link"]) : nothing

    if links != nothing && haskey(links, "next") && (result_limit < 0 || per_page < result_limit)
        p = Pager(links["next"], headers)
        for page in p
            push!(pages, page)

            if result_limit > 0 && length(pages) * 30 >= result_limit
                break
            end
        end
    end

    return pages
end

function get_pages(u::HttpCommon.URI, result_limit::Int = -1, per_page::Int = 30; headers = Dict(), options...)
    r = Requests.get(u; headers = headers, options...)
    handle_error(r)

    return _get_pages(r, result_limit, per_page; headers = headers, options...)
end

# get_paged gives you an Array{Response,1}
# get_items_from_pages turns that into an Array{Dict,1}
# each Dict is one of the items in the paginated list of results
function get_items_from_pages(pages)
    isempty(pages) && return Dict[]

    results = Requests.json(pages[1])
    for page in pages[2:end]
        parsed = Requests.json(page)
        append!(results, parsed)
    end

    return results
end
