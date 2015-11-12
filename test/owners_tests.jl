import GitHub
import JSON
using Base.Test

owner_full_json = JSON.parse(
"""
{
  "login": "octocat",
  "id": 1,
  "avatar_url": "https://github.com/images/error/octocat_happy.gif",
  "gravatar_id": "",
  "url": "https://api.github.com/users/octocat",
  "html_url": "https://github.com/octocat",
  "followers_url": "https://api.github.com/users/octocat/followers",
  "following_url": "https://api.github.com/users/octocat/following/other_user",
  "gists_url": "https://api.github.com/users/octocat/gists/gist_id",
  "starred_url": "https://api.github.com/users/octocat/starred/owner/repo",
  "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
  "organizations_url": "https://api.github.com/users/octocat/orgs",
  "repos_url": "https://api.github.com/users/octocat/repos",
  "events_url": "https://api.github.com/users/octocat/events/privacy",
  "received_events_url": "https://api.github.com/users/octocat/received_events",
  "type": "User",
  "site_admin": false,
  "name": "monalisa octocat",
  "company": "GitHub",
  "blog": "https://github.com/blog",
  "location": "San Francisco",
  "email": "octocat@github.com",
  "hireable": false,
  "bio": "There once was...",
  "public_repos": 2,
  "public_gists": 1,
  "followers": 20,
  "following": 0,
  "created_at": "2008-01-14T04:33:35Z",
  "updated_at": "2008-01-14T04:33:35Z",
  "total_private_repos": 100,
  "owned_private_repos": 100,
  "private_gists": 81,
  "disk_usage": 10000,
  "collaborators": 8,
  "plan": {
    "name": "Medium",
    "space": 400,
    "private_repos": 20,
    "collaborators": 0
  }
}
"""
)

owner_full_result = GitHub.Owner(
    Nullable(GitHub.GitHubString(owner_full_json["type"])),
    Nullable(GitHub.GitHubString(owner_full_json["email"])),
    Nullable(GitHub.GitHubString(owner_full_json["name"])),
    Nullable(GitHub.GitHubString(owner_full_json["login"])),
    Nullable(GitHub.GitHubString(owner_full_json["bio"])),
    Nullable(GitHub.GitHubString(owner_full_json["company"])),
    Nullable(GitHub.GitHubString(owner_full_json["location"])),
    Nullable(GitHub.GitHubString(owner_full_json["gravatar_id"])),
    Nullable(Int(owner_full_json["id"])),
    Nullable(Int(owner_full_json["public_repos"])),
    Nullable(Int(owner_full_json["owned_private_repos"])),
    Nullable(Int(owner_full_json["total_private_repos"])),
    Nullable(Int(owner_full_json["public_gists"])),
    Nullable(Int(owner_full_json["private_gists"])),
    Nullable(Int(owner_full_json["followers"])),
    Nullable(Int(owner_full_json["following"])),
    Nullable(Int(owner_full_json["collaborators"])),
    Nullable(HttpCommon.URI(owner_full_json["blog"])),
    Nullable(HttpCommon.URI(owner_full_json["url"])),
    Nullable(HttpCommon.URI(owner_full_json["html_url"])),
    Nullable(Dates.DateTime(chop(owner_full_json["updated_at"]))),
    Nullable(Dates.DateTime(chop(owner_full_json["created_at"]))),
    Nullable{Dates.DateTime}(),
    Nullable(Bool(owner_full_json["hireable"])),
    Nullable(Bool(owner_full_json["site_admin"]))
)

@test GitHub.Owner(owner_full_json) == owner_full_result

owner_sparse_json = JSON.parse(
"""
{
  "id": 1,
  "gravatar_id": "",
  "url": "https://api.github.com/users/octocat",
  "html_url": "https://github.com/octocat",
  "followers_url": "https://api.github.com/users/octocat/followers",
  "received_events_url": "https://api.github.com/users/octocat/received_events",
  "type": "User",
  "login": "octocat",
  "name": "monalisa octocat",
  "company": "GitHub",
  "blog": "https://github.com/blog",
  "location": "San Francisco",
  "updated_at": "2008-01-14T04:33:35Z",
  "total_private_repos": 100,
  "disk_usage": 10000,
  "collaborators": 8,
  "hireable": false
}
"""
)

owner_sparse_result = GitHub.Owner(
    Nullable(GitHub.GitHubString(owner_sparse_json["type"])),
    Nullable{GitHub.GitHubString}(),
    Nullable(GitHub.GitHubString(owner_sparse_json["name"])),
    Nullable(GitHub.GitHubString(owner_sparse_json["login"])),
    Nullable{GitHub.GitHubString}(),
    Nullable(GitHub.GitHubString(owner_sparse_json["company"])),
    Nullable(GitHub.GitHubString(owner_sparse_json["location"])),
    Nullable(GitHub.GitHubString(owner_sparse_json["gravatar_id"])),
    Nullable(Int(owner_sparse_json["id"])),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable(Int(owner_sparse_json["total_private_repos"])),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable(Int(owner_sparse_json["collaborators"])),
    Nullable(HttpCommon.URI(owner_sparse_json["blog"])),
    Nullable(HttpCommon.URI(owner_sparse_json["url"])),
    Nullable(HttpCommon.URI(owner_sparse_json["html_url"])),
    Nullable(Dates.DateTime(chop(owner_sparse_json["updated_at"]))),
    Nullable{Dates.DateTime}(),
    Nullable{Dates.DateTime}(),
    Nullable(Bool(owner_sparse_json["hireable"])),
    Nullable{Bool}()
)

@test GitHub.Owner(owner_sparse_json) == owner_sparse_result
