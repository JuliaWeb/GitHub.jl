abstract GitHubType

function github_obj_from_type(data::Dict)
    t = get(data, "type", nothing)
    if t == "User"
        return User(data)
    elseif t == "Organization"
        return Organization(data)
    end
end

function getnullable{T}(data::Dict, key, ::Type{T})
    if haskey(data, key)
        val = data[key]
        if !(isa(val, Void))
            if T == Dates.DateTime
                val = chopz(val)
            end
            return Nullable{T}(T(val))
        end
    end
    return Nullable{T}()
end

# ISO 8601 allows for a trailing 'Z' to indicate that the given time is UTC.
# Julia's Dates.DateTime constructor doesn't support this, but GitHub's time
# strings can contain it. This method ensures that a string's trailing 'Z',
# if present, has been removed.
function chopz(str::AbstractString)
    if !(isempty(str)) && last(str) == 'Z'
        return chop(str)
    end
    return str
end

# Given a type defined as:
#
# type G <: GitHubType
#     a::Nullable{A}
#     b::Nullable{B}
#     ⋮
# end
#
# ...calling `extract_github_type(::Type{G}, data::Dict)` will parse the given
# dictionary into the the type `G` with the expectation that the fieldnames of
# `G` are keys of `data`, and the corresponding values can be converted to the
# given types. For example, extraction of the first field above results in
# the call `Nullable{A}(A(data["a"]))` (assuming that data["a"] exists).
@generated function extract_github_type{G<:GitHubType}(::Type{G}, data::Dict)
    types = G.types
    fields = fieldnames(G)
    args = Vector{Expr}(length(fields))
    for i in eachindex(fields)
        k, T = string(fields[i]), first(types[i].parameters)
        args[i] = :(getnullable(data, $k, $T))
    end
    return :(G($(args...)))
end
