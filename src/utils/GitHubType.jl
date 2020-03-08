"""
    abstract type GitHubType end

A `GitHubType` is a Julia type representation of a JSON object defined by the GitHub
API. Generally:

 - The fields of these types should correspond to keys in the JSON object. In the event
   the JSON object has a "type" key, the corresponding field name used should be `typ`
   (since `type` is a reserved word in Julia).

 - The method `name` should be defined on every `GitHubType`. This method returns the
   type's identity in the form used for URI construction. For example, `name` called on an
   `Owner` will return the owner's login, while `name` called on a `Commit` will return
   the commit's sha.

 - A GitHubType's field types should be Union{Nothing, T} of either: concrete types, a
   Vectors of concrete types, or Dicts.

"""
abstract type GitHubType end

"""
    @ghdef typeexpr

Define a new `GitHubType` specified by `typeexpr`, adding default constructors for
conversions from `Dict`s and keyword arguments.
"""
macro ghdef(expr)
    # a very simplified form of Base.@kwdef
    expr = macroexpand(__module__, expr) # to expand @static
    expr isa Expr && expr.head == :struct && expr.args[2] isa Symbol || error("Invalid usage of @ghtype")
    T = expr.args[2]
    expr.args[2] = :($T <: GitHubType)

    params_ex = Expr(:parameters)
    call_args = Any[]

    for ei in expr.args[3].args
        if ei isa Expr && ei.head == :(::)
            var = ei.args[1]
            S  = ei.args[2]
            push!(params_ex.args, Expr(:kw, var, nothing))
            push!(call_args, :($var === nothing ? $var : prune_github_value($var, unwrap_union_types($S))))
        end
    end
    quote
        Base.@__doc__($(esc(expr)))
        ($(esc(T)))($params_ex) = ($(esc(T)))($(call_args...))
        $(esc(T))(data::Dict) = json2github($T, data)
    end
end

function Base.:(==)(a::GitHubType, b::GitHubType)
    if typeof(a) != typeof(b)
        return false
    end

    for field in fieldnames(typeof(a))
        aval, bval = getfield(a, field), getfield(b, field)
        if (aval === nothing) == (bval === nothing)
            if aval !== nothing && aval != bval
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
name(g::GitHubType) = namefield(g)

########################################
# Converting JSON Dicts to GitHubTypes #
########################################

# Unwrap Union{Nothing, Foo} to just Foo
unwrap_union_types(T) = T
function unwrap_union_types(T::Union)
    if T.a == Nothing
        return T.b
    end
    return T.a
end

function extract_nullable(data::Dict, key, ::Type{T}) where {T}
    if haskey(data, key)
        val = data[key]
        if val !== nothing
            if T <: Vector
                V = eltype(T)
                return V[prune_github_value(v, unwrap_union_types(V)) for v in val]
            else
                return prune_github_value(val, unwrap_union_types(T))
            end
        end
    end
    return nothing
end

prune_github_value(val::T, ::Type{Any}) where {T} = val
prune_github_value(val::T, ::Type{T}) where {T} = val
prune_github_value(val, ::Type{T}) where {T} = T(val)
prune_github_value(val::AbstractString, ::Type{Dates.DateTime}) = Dates.DateTime(chopz(val))

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
@generated function json2github(::Type{G}, data::Dict) where {G<:GitHubType}
    types = unwrap_union_types.(collect(G.types))
    fields = fieldnames(G)
    args = Vector{Expr}(undef, length(fields))
    for i in eachindex(fields)
        field, T = fields[i], types[i]
        key = field == :typ ? "type" : string(field)
        args[i] = :(extract_nullable(data, $key, $T))
    end
    return :(G($(args...))::G)
end


#############################################
# Converting GitHubType Dicts to JSON Dicts #
#############################################

github2json(val) = val
github2json(uri::HTTP.URI) = string(uri)
github2json(dt::Dates.DateTime) = string(dt) * "Z"
github2json(v::Vector) = [github2json(i) for i in v]

function github2json(g::GitHubType)
    results = Dict()
    for field in fieldnames(typeof(g))
        val = getfield(g, field)
        if !(val == nothing)
            key = field == :typ ? "type" : string(field)
            results[key] = github2json(val)
        end
    end
    return results
end

function github2json(data::Dict{K}) where {K}
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
    if get(io, :compact, false)
        uri_id = namefield(g)
        if uri_id === nothing
            print(io, typeof(g), "(…)")
        else
            print(io, typeof(g), "($(repr(uri_id)))")
        end
    else
        print(io, "$(typeof(g)) (all fields are Union{Nothing, T}):")
        for field in fieldnames(typeof(g))
            val = getfield(g, field)
            if !(val === nothing)
                println(io)
                print(io, "  $field: ")
                if isa(val, Vector)
                    print(io, typeof(val))
                else
                    show(IOContext(io, :compact => true), val)
                end
            end
        end
    end
end
