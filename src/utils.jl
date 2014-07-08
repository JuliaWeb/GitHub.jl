
# Utility -------

function github_obj_from_type(data::Dict)
    t = get(data, "type", nothing)

    if t == "User"
        return User(data)
    elseif t == "Organization"
        return Organization(data)
    end
end

# Pagination Helper Functions

# Parses a Link header into the links it represents
function parse_link_header(s::String)
  results = Dict{String,URI}()
  # <url>; rel="name", <url2>; rel="name2", ...
  for m in eachmatch(r"<([^>]+)>; rel=\"(\w+)\",? ?", s)
    results[m.captures[2]] = URI(m.captures[1])
  end
  return results
end

# Given a URI, fetches it
# Returns the response and the next link, if any.
function next_page(next_link::URI)
  r = get(next_link)
  handle_error(r)
  links = parse_link_header(r.headers["Link"])
  if haskey(links, "next")
    return (r, links["next"])
  end
  return (r, nothing)
end

# To make pages iterable
type Pager
  initial_link::URI
end
Base.start(p::Pager) = p.initial_link
Base.next(p::Pager, l::URI) = next_page(l)
Base.done(p::Pager, l::URI) = false
Base.done(p::Pager, l::Nothing) = true

# Designed to be called by functions that want paginated access
# u and all the keyword argument comprise the call you would have make to Requests.get
# result_limit is the desired number of results; the default (-1) indicates all results
# per_page is the number of results to expect per page; default is 30, GitHub's default
# Returns an Array of Responses (1 per page)
function get_pages(u::URI,result_limit::Int=-1,per_page::Int=30;options...)
  r = get(u;options...)
  handle_error(r)

  pages = [r]
  links = parse_link_header(r.headers["Link"])
  if haskey(links,"next")
    p = Pager(links["next"])
    for page in p
      push!(pages,page)
    end
  end
  return pages
end

# get_paged gives you an Array{Response,1}
# get_items_from_pages turns that into an Array{Dict,1}
# each Dict is one of the items in the paginated list of results
function get_items_from_pages(pages)
  results = Dict[]
  for page in pages
    parsed = JSON.parse(page.data)
    append!(results,parsed)
  end
  return results
end
