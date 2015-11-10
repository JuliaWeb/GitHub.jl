abstract GitHubType

typealias GitHubString UTF8String

# overloaded by various GitHubTypes to allow for more generic input to API
# functions that require a name to construct URI paths
name(str::AbstractString) = str

function extract_nullable{T}(data::Dict, key, ::Type{T})
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
# given types.

const EMPTY_DICT = Dict()

@generated function extract_github_type{G<:GitHubType}(::Type{G}, data::Dict, replacements::Dict=EMPTY_DICT)
    types = G.types
    fields = fieldnames(G)
    args = Vector{Expr}(length(fields))
    for i in eachindex(fields)
        k, T = keyfunc(string(fields[i])), first(types[i].parameters)
        args[i] = :(extract_nullable(data, get(replacements, $k, $k), $T))
    end
    return :(G($(args...)))
end

function Base.show(io::IO, obj::GitHubType)
    print(io, "$(typeof(obj)):")
    for field in fieldnames(obj)
        val = getfield(obj, field)
        if !(isnull(val))
            println(io)
            print(io, "  $field : $(get(val))")
        end
    end
end

Base.showcompact(io::IO, obj::GitHubType) = print(io, "$(typeof(obj))")
