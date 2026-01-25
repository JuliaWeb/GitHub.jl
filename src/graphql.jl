###############
# GraphQL API #
###############

"""
    graphql_query(api::GitHubAPI, query::AbstractString; options...)

Execute a GraphQL query against the GitHub API.

# Arguments
- `api::GitHubAPI`: The GitHub API instance.
- `query::AbstractString`: The GraphQL query string.

# Keywords
- `auth`: Authentication method (default: AnonymousAuth()).
- Other options passed to the request.

# Returns
- The JSON response from the GraphQL API as a Dict.

# Examples
```julia
query = \"\"\"
{
  viewer {
    login
  }
}
\"\"\"

result = graphql_query(query; auth=auth)
println(result["data"]["viewer"]["login"])
```
"""
@api_default function graphql_query(api::GitHubAPI, query::AbstractString; options...)
    params = Dict("query" => query)
    return gh_post_json(api, "/graphql"; params=params, options...)
end