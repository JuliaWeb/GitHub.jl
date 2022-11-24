@ghdef mutable struct Label
    name::Union{String, Nothing}
    default::Union{Bool, Nothing}
    id::Union{Int, Nothing}
    color::Union{String, Nothing}
    node_id::Union{String, Nothing}
    url::Union{String, Nothing}
    description::Union{String, Nothing}
end

namefield(label::Label) = label.name

Label(name::AbstractString) = Label(Dict("name" => name))
