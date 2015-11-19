import GitHub
import JSON
using Base.Test

# This file tests various GitHubType constructors. To test for proper Nullable
# handling, most fields have been removed from the JSON samples used below.
# Sample fields were selected in order to cover the full range of type behavior,
# e.g. if the GitHubType has a few Nullable{Dates.DateTime} fields, at least one
# of those fields should be present in the JSON sample. In addition, at least
# one `null`-valued field is present in each JSON sample.

#########
# Owner #
#########

owner_json = JSON.parse(
"""
{
  "id": 1,
  "email": null,
  "html_url": "https://github.com/octocat",
  "login": "octocat",
  "updated_at": "2008-01-14T04:33:35Z",
  "hireable": false
}
"""
)

owner_result = GitHub.Owner(
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(GitHub.GitHubString(owner_json["login"])),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{Int}(Int(owner_json["id"])),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(HttpCommon.URI(owner_json["html_url"])),
    Nullable{Dates.DateTime}(Dates.DateTime(chop(owner_json["updated_at"]))),
    Nullable{Dates.DateTime}(),
    Nullable{Dates.DateTime}(),
    Nullable{Bool}(Bool(owner_json["hireable"])),
    Nullable{Bool}()
)

@test GitHub.Owner(owner_json) == owner_result

########
# Repo #
########

repo_json = JSON.parse(
"""
{
  "id": 1296269,
  "owner": {
    "login": "octocat"
  },
  "parent": {
    "name": "test-parent"
  },
  "name": "Hello-World",
  "private": false,
  "url": "https://api.github.com/repos/octocat/Hello-World",
  "language": null,
  "pushed_at": "2011-01-26T19:06:43Z",
  "permissions": {
    "admin": false,
    "push": false,
    "pull": true
  }
}
"""
)

repo_result = GitHub.Repo(
    Nullable{GitHub.GitHubString}(GitHub.GitHubString(repo_json["name"])),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.Owner}(GitHub.Owner(repo_json["owner"])),
    Nullable{GitHub.Repo}(GitHub.Repo(repo_json["parent"])),
    Nullable{GitHub.Repo}(),
    Nullable{Int}(Int(repo_json["id"])),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{HttpCommon.URI}(HttpCommon.URI(repo_json["url"])),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{Dates.DateTime}(Dates.DateTime(chop(repo_json["pushed_at"]))),
    Nullable{Dates.DateTime}(),
    Nullable{Dates.DateTime}(),
    Nullable{Bool}(),
    Nullable{Bool}(),
    Nullable{Bool}(),
    Nullable{Bool}(),
    Nullable{Bool}(Bool(repo_json["private"])),
    Nullable{Bool}(),
    Nullable{Dict}(repo_json["permissions"])
)

@test GitHub.Repo(repo_json) == repo_result

##########
# Commit #
##########

commit_json = JSON.parse(
"""
{
  "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "html_url": null,
  "commit": {
    "message": "Fix all the bugs",
    "comment_count": 0
  },
  "author": {
    "login": "octocat"
  },
  "parents": [
    {
      "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
    },
    {
      "sha": "7ed9340c309dd91757664cee6d857d161c14e095"
    }
  ],
  "stats": {
    "total": 108
  },
  "files": [
    {
      "filename": "file1.txt"
    },
    {
      "filename": "file2.txt"
    }
  ]
 }
"""
)

commit_result = GitHub.Commit(
    Nullable{GitHub.GitHubString}(GitHub.GitHubString(commit_json["sha"])), # sha
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.Owner}(GitHub.Owner(commit_json["author"])),
    Nullable{GitHub.Owner}(),
    Nullable{GitHub.Commit}(GitHub.Commit(commit_json["commit"])),
    Nullable{HttpCommon.URI}(HttpCommon.URI(commit_json["url"])),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{Vector{GitHub.Commit}}(map(GitHub.Commit, commit_json["parents"])),
    Nullable{Dict}(commit_json["stats"]),
    Nullable{Vector{GitHub.Content}}(map(GitHub.Content, commit_json["files"])),
    Nullable{Int}()
)

@test GitHub.Commit(commit_json) == commit_result

###########
# Comment #
###########

comment_json = JSON.parse(
"""
{
  "url": "https://api.github.com/repos/octocat/Hello-World/comments/1",
  "id": 1,
  "position": null,
  "body": "Great stuff",
  "user": {
    "login": "octocat"
  },
  "created_at": "2011-04-14T16:00:49Z"
}
"""
)

comment_result = GitHub.Comment(
    Nullable{GitHub.GitHubString}(GitHub.GitHubString(comment_json["body"])),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{Int}(Int(comment_json["id"])),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Dates.DateTime}(Dates.DateTime(chop(comment_json["created_at"]))),
    Nullable{Dates.DateTime}(),
    Nullable{HttpCommon.URI}(HttpCommon.URI(comment_json["url"])),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{GitHub.Owner}(GitHub.Owner(comment_json["user"]))
)

@test GitHub.Comment(comment_json) == comment_result

###########
# Content #
###########

content_json = JSON.parse(
"""
{
  "type": "file",
  "size": 625,
  "encoding": null,
  "url": "https://api.github.com/repos/octokit/octokit.rb/contents/lib/octokit.rb"
}
"""
)

content_result = GitHub.Content(
    Nullable{GitHub.GitHubString}(GitHub.GitHubString(content_json["type"])),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{HttpCommon.URI}(HttpCommon.URI(content_json["url"])),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{Int}(content_json["size"])
)

@test GitHub.Content(content_json) == content_result

##########
# Status #
##########

status_json = JSON.parse(
"""
{
  "created_at": "2012-07-20T01:19:13Z",
  "description": "Build has completed successfully",
  "id": 1,
  "context": null,
  "url": "https://api.github.com/repos/octocat/Hello-World/statuses/1",
  "creator": {
    "login": "octocat"
  }
}
"""
)

status_result = GitHub.Status(
    Nullable{Int}(Int(status_json["id"])),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(GitHub.GitHubString(status_json["description"])),
    Nullable{GitHub.GitHubString}(),
    Nullable{HttpCommon.URI}(HttpCommon.URI(status_json["url"])),
    Nullable{HttpCommon.URI}(),
    Nullable{Dates.DateTime}(Dates.DateTime(chop(status_json["created_at"]))),
    Nullable{Dates.DateTime}(),
    Nullable{GitHub.Owner}(GitHub.Owner(status_json["creator"]))
)

@test GitHub.Status(status_json) == status_result

#########
# Issue #
#########

issue_json = JSON.parse(
"""
{
  "url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
  "number": 1347,
  "title": "Found a bug",
  "user": {
    "login": "octocat"
  },
  "labels": [
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
      "name": "bug",
      "color": "f29513"
    }
  ],
  "pull_request": {
    "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
    "html_url": "https://github.com/octocat/Hello-World/pull/1347",
    "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
    "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch"
  },
  "locked": false,
  "closed_at": null,
  "created_at": "2011-04-22T13:33:48Z"
}
"""
)

issue_result = GitHub.Issue(
    Nullable{Int}(),
    Nullable{Int}(Int(issue_json["number"])),
    Nullable{Int}(),
    Nullable{GitHub.GitHubString}(GitHub.GitHubString(issue_json["title"])),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.GitHubString}(),
    Nullable{GitHub.Owner}(GitHub.Owner(issue_json["user"])),
    Nullable{GitHub.Owner}(),
    Nullable{GitHub.Owner}(),
    Nullable{Dates.DateTime}(Dates.DateTime(chop(issue_json["created_at"]))),
    Nullable{Dates.DateTime}(),
    Nullable{Dates.DateTime}(),
    Nullable{Vector{Dict}}(Vector{Dict}(issue_json["labels"])),
    Nullable{Dict}(),
    Nullable{Dict}(issue_json["pull_request"]),
    Nullable{HttpCommon.URI}(HttpCommon.URI(issue_json["url"])),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{HttpCommon.URI}(),
    Nullable{Bool}(Bool(issue_json["locked"])) 
)

@test GitHub.Issue(issue_json) == issue_result
