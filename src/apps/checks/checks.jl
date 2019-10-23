module Checks
import ..GitHub: @ghdef, GitHubType
export Action, Image, Annotation, Output

@ghdef mutable struct Action
    label::String
    description::String
    identifier::String
end

@ghdef mutable struct Image
    alt::String
    image_url::String
    caption::Union{String, Nothing}
end

@ghdef mutable struct Annotation
    filename::String
    blob_href::String
    start_line::Int
    end_line::Int
    warning_level::String
    message::String
    title::Union{String, Nothing}
    raw_details::Union{String, Nothing}
end

@ghdef mutable struct Output
    title::String
    summary::String
    text::Union{String, Nothing}
    annotations::Vector{Annotation}
    images::Vector{Image}
end

end
using .Checks
