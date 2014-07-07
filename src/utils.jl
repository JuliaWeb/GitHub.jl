
# Utility -------

function github_obj_from_type(data::Dict)
    t = get(data, "type", nothing)

    if t == "User"
        return User(data)
    elseif t == "Organization"
        return Organization(data)
    end
end

function parse_link_header(s::String)
  results = Dict{String,URI}()
  # <url>; rel="name", <url2>; rel="name2", ...
  for m in eachmatch(r"<([^>]+)>; rel=\"(\w+)\",? ?", s)
    results[m.captures[2]] = URI(m.captures[1])
  end
  return results
end
