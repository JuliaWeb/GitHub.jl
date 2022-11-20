###############
# Topic Type #
###############

@ghdef mutable struct Topic
    name::String
end

Topic(name::AbstractString) = Commit(Dict("name" => name))

namefield(topic::Topic) = topic.name

###############
# API Methods #
###############

@api_default function topics(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/topics"; options...)
    return map(Topic, results["names"]), page_data
end
