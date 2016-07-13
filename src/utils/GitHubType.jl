##############
# GitHubType #
##############
# A `GitHubType` is a Julia type representation of a JSON object defined by the
# GitHub API. Generally:
#
# - The fields of these types should correspond to keys in the JSON object. In
#   the event the JSON object has a "type" key, the corresponding field name
#   used should be `typ` (since `type` is a reserved word in Julia).
#
# - The method `name` should be defined on every GitHubType. This method
#   returns the type's identity in the form used for URI construction. For
#   example, `name` called on an `Owner` will return the owner's login, while
#   `name` called on a `Commit` will return the commit's sha.
#
# - A GitHubType's field types should be Nullables of either concrete types, a
#   Vectors of concrete types, or Dicts.

abstract GitHubType

typealias GitHubString Compat.UTF8String

function @compat(Base.:(==))(a::GitHubType, b::GitHubType)
    if typeof(a) != typeof(b)
        return false
    end

    for field in fieldnames(a)
        aval, bval = getfield(a, field), getfield(b, field)
        if isnull(aval) == isnull(bval)
            if !(isnull(aval)) && get(aval) != get(bval)
                return false
            end
        else
            return false
        end
    end

    return true
end

# `namefield` is overloaded by various GitHubTypes to allow for more generic
# input to AP functions that require a name to construct URI paths via `name`
name(val) = val
name(g::GitHubType) = get(namefield(g))

########################################
# Converting JSON Dicts to GitHubTypes #
########################################

function extract_nullable{T}(data::Dict, key, ::Type{T})
    if haskey(data, key)
        val = data[key]
        if !(isa(val, Void))
            if T <: Vector
                V = eltype(T)
                return Nullable{T}(V[prune_github_value(v, V) for v in val])
            else
                return Nullable{T}(prune_github_value(val, T))
            end
        end
    end
    return Nullable{T}()
end

prune_github_value{T}(val, ::Type{T}) = T(val)
prune_github_value(val, ::Type{Dates.DateTime}) = Dates.DateTime(chopz(val))

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

# Calling `json2github(::Type{G<:GitHubType}, data::Dict)` will parse the given
# dictionary into the type `G` with the expectation that the fieldnames of
# `G` are keys of `data`, and the corresponding values can be converted to the
# given field types.
@generated function json2github{G<:GitHubType}(::Type{G}, data::Dict)
    types = G.types
    fields = fieldnames(G)
    args = Vector{Expr}(length(fields))
    for i in eachindex(fields)
        field, T = fields[i], first(types[i].parameters)
        key = field == :typ ? "type" : string(field)
        args[i] = :(extract_nullable(data, $key, $T))
    end
    return :(G($(args...))::G)
end

#############################################
# Converting GitHubType Dicts to JSON Dicts #
#############################################

github2json(val) = val
github2json(uri::HttpCommon.URI) = string(uri)
github2json(dt::Dates.DateTime) = string(dt) * "Z"
github2json(v::Vector) = [github2json(i) for i in v]

function github2json(g::GitHubType)
    results = Dict()
    for field in fieldnames(g)
        val = getfield(g, field)
        if !(isnull(val))
            key = field == :typ ? "type" : string(field)
            results[key] = github2json(get(val))
        end
    end
    return results
end

function github2json{K}(data::Dict{K})
    results = Dict{K,Any}()
    for (key, val) in data
        results[key] = github2json(val)
    end
    return results
end

###################
# Pretty Printing #
###################

function Base.show(io::IO, g::GitHubType)
    print(io, "$(typeof(g)) (all fields are Nullable):")
    for field in fieldnames(g)
        val = getfield(g, field)
        if !(isnull(val))
            gotval = get(val)
            println(io)
            print(io, "  $field: ")
            if isa(gotval, Vector)
                print(io, typeof(gotval))
            else
                showcompact(io, gotval)
            end
        end
    end
end

function Base.showcompact(io::IO, g::GitHubType)
    uri_id = namefield(g)
    if isnull(uri_id)
        print(io, typeof(g), "(…)")
    else
        print(io, typeof(g), "($(repr(get(uri_id))))")
    end
end
