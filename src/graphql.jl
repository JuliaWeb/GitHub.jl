###############
# GraphQL API #
###############

const GRAPHQL_INTROSPECTION_QUERY = """
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args {
        ...InputValue
      }
    }
  }
}

fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}

fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
"""

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

"""
    graphql_schema_introspection(api::GitHubAPI; options...)

Perform GraphQL schema introspection to retrieve the full schema.

# Arguments
- `api::GitHubAPI`: The GitHub API instance.

# Keywords
- `auth`: Authentication method (default: AnonymousAuth()).
- Other options passed to the request.

# Returns
- The GraphQL schema as a JSON object.
"""
@api_default function graphql_schema_introspection(api::GitHubAPI; options...)
    return graphql_query(api, GRAPHQL_INTROSPECTION_QUERY; options...)
end

"""
    graphql_viewer(api::GitHubAPI; options...)

Get information about the authenticated user (viewer).

# Arguments
- `api::GitHubAPI`: The GitHub API instance.

# Keywords
- `auth`: Authentication method (default: AnonymousAuth()).
- Other options passed to the request.

# Returns
- Viewer information as a JSON object.
"""
@api_default function graphql_viewer(api::GitHubAPI; options...)
    query = """
    {
      viewer {
        login
        name
        email
        avatarUrl
      }
    }
    """
    return graphql_query(api, query; options...)
end