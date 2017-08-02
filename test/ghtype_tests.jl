import JSON
using GitHub, GitHub.name, GitHub.Branch
using Base.Test

# This file tests various GitHubType constructors. To test for proper Nullable
# handling, most fields have been removed from the JSON samples used below.
# Sample fields were selected in order to cover the full range of type behavior,
# e.g. if the GitHubType has a few Nullable{Dates.DateTime} fields, at least one
# of those fields should be present in the JSON sample.

function test_show(g::GitHub.GitHubType)
    tmpio = IOBuffer()
    show(tmpio, g)

    # basically trivial, but proves that things aren't completely broken
    @test repr(g) == String(take!(tmpio))

    tmpio = IOBuffer()
    showcompact(tmpio, g)

    @test "$(typeof(g))($(repr(name(g))))" == String(take!(tmpio))
end

@testset "Owner" begin
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

    owner_result = Owner(
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(String(owner_json["login"])),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
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

    @test Owner(owner_json) == owner_result
    @test name(Owner(owner_json["login"])) == name(owner_result)
    @test setindex!(GitHub.github2json(owner_result), nothing, "email") == owner_json

    test_show(owner_result)
end

@testset "Repo" begin
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
      "full_name": "octocat/Hello-World",
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

    repo_result = Repo(
        Nullable{String}(),
        Nullable{String}(String(repo_json["full_name"])),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{Owner}(Owner(repo_json["owner"])),
        Nullable{Repo}(Repo(repo_json["parent"])),
        Nullable{Repo}(),
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

    @test Repo(repo_json) == repo_result
    @test name(Repo(repo_json["full_name"])) == name(repo_result)
    @test setindex!(GitHub.github2json(repo_result), nothing, "language") == repo_json

    test_show(repo_result)
end

@testset "Commit" begin
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

    commit_result = Commit(
        Nullable{String}(String(commit_json["sha"])),
        Nullable{String}(),
        Nullable{Owner}(Owner(commit_json["author"])),
        Nullable{Owner}(),
        Nullable{Commit}(Commit(commit_json["commit"])),
        Nullable{HttpCommon.URI}(HttpCommon.URI(commit_json["url"])),
        Nullable{HttpCommon.URI}(),
        Nullable{HttpCommon.URI}(),
        Nullable{Vector{Commit}}(map(Commit, commit_json["parents"])),
        Nullable{Dict}(commit_json["stats"]),
        Nullable{Vector{Content}}(map(Content, commit_json["files"])),
        Nullable{Int}()
    )

    @test Commit(commit_json) == commit_result
    @test name(Commit(commit_json["sha"])) == name(commit_result)
    @test setindex!(GitHub.github2json(commit_result), nothing, "html_url") == commit_json

    test_show(commit_result)
end

@testset "Branch" begin
    branch_json = JSON.parse(
    """
    {
      "name": "master",
      "sha": null,
      "protection": {
        "enabled": false,
        "required_status_checks": {
          "enforcement_level": "off",
          "contexts": []
        }
      },
      "commit": {
        "sha": "7fd1a60b01f91b314f59955a4e4d4e80d8edf11d"
      },
      "user": {
        "login": "octocat"
      },
      "repo": {
        "full_name": "octocat/Hello-World"
      }
    }
    """
    )

    branch_result = Branch(
        Nullable{String}(String(branch_json["name"])),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{Commit}(Commit(branch_json["commit"])),
        Nullable{Owner}(Owner(branch_json["user"])),
        Nullable{Repo}(Repo(branch_json["repo"])),
        Nullable{Dict}(),
        Nullable{Dict}(branch_json["protection"])
    )

    @test Branch(branch_json) == branch_result
    @test name(Branch(branch_json["name"])) == name(branch_result)
    @test setindex!(GitHub.github2json(branch_result), nothing, "sha") == branch_json

    test_show(branch_result)
end

@testset "Comment" begin
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

    comment_result = Comment(
        Nullable{String}(String(comment_json["body"])),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
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
        Nullable{Owner}(Owner(comment_json["user"]))
    )

    @test Comment(comment_json) == comment_result
    @test name(Comment(comment_json["id"])) == name(comment_result)
    @test setindex!(GitHub.github2json(comment_result), nothing, "position") == comment_json

    test_show(comment_result)
end

@testset "Content" begin
    content_json = JSON.parse(
    """
    {
      "type": "file",
      "path": "lib/octokit.rb",
      "size": 625,
      "encoding": null,
      "url": "https://api.github.com/repos/octokit/octokit.rb/contents/lib/octokit.rb"
    }
    """
    )

    content_result = Content(
        Nullable{String}(String(content_json["type"])),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(String(content_json["path"])),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{HttpCommon.URI}(HttpCommon.URI(content_json["url"])),
        Nullable{HttpCommon.URI}(),
        Nullable{HttpCommon.URI}(),
        Nullable{HttpCommon.URI}(),
        Nullable{Int}(content_json["size"])
    )

    @test Content(content_json) == content_result
    @test name(Content(content_json["path"])) == name(content_result)
    @test setindex!(GitHub.github2json(content_result), nothing, "encoding") == content_json

    test_show(content_result)
end


@testset "Status" begin
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
      },
      "statuses": [
        {
          "id": 366962428
        }
      ],
      "repository": {
        "full_name": "JuliaWeb/GitHub.jl"
      }
    }
    """
    )

    status_result = Status(
        Nullable{Int}(Int(status_json["id"])),
        Nullable{Int}(),
        Nullable{String}(),
        Nullable{String}(String(status_json["description"])),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{HttpCommon.URI}(HttpCommon.URI(status_json["url"])),
        Nullable{HttpCommon.URI}(),
        Nullable{Dates.DateTime}(Dates.DateTime(chop(status_json["created_at"]))),
        Nullable{Dates.DateTime}(),
        Nullable{Owner}(Owner(status_json["creator"])),
        Nullable{Repo}(Repo(status_json["repository"])),
        Nullable{Vector{Status}}(map(Status, status_json["statuses"]))
    )

    @test Status(status_json) == status_result
    @test name(Status(status_json["id"])) == name(status_result)
    @test setindex!(GitHub.github2json(status_result), nothing, "context") == status_json

    test_show(status_result)
end

@testset "PullRequest" begin
    pr_json = JSON.parse(
    """
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
      "number": 1347,
      "body": "Please pull these awesome changes",
      "assignee": {
        "login": "octocat"
      },
      "milestone": {
        "id": 1002604,
        "number": 1,
        "state": "open",
        "title": "v1.0"
      },
      "locked": false,
      "created_at": "2011-01-26T19:01:12Z",
      "head": {
        "ref": "new-topic"
      }
    }
    """
    )

    pr_result = PullRequest(
        Nullable{Branch}(),
        Nullable{Branch}(Branch(pr_json["head"])),
        Nullable{Int}(Int(pr_json["number"])),
        Nullable{Int}(),
        Nullable{Int}(),
        Nullable{Int}(),
        Nullable{Int}(),
        Nullable{Int}(),
        Nullable{Int}(),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{String}(String(pr_json["body"])),
        Nullable{String}(),
        Nullable{Dates.DateTime}(Dates.DateTime(chop(pr_json["created_at"]))),
        Nullable{Dates.DateTime}(),
        Nullable{Dates.DateTime}(),
        Nullable{Dates.DateTime}(),
        Nullable{HttpCommon.URI}(HttpCommon.URI(pr_json["url"])),
        Nullable{HttpCommon.URI}(),
        Nullable{Owner}(Owner(pr_json["assignee"])),
        Nullable{Owner}(),
        Nullable{Owner}(),
        Nullable{Dict}(pr_json["milestone"]),
        Nullable{Dict}(),
        Nullable{Bool}(),
        Nullable{Bool}(),
        Nullable{Bool}(pr_json["locked"])
    )

    @test PullRequest(pr_json) == pr_result
    @test name(PullRequest(pr_json["number"])) == name(pr_result)
    @test GitHub.github2json(pr_result) == pr_json

    test_show(pr_result)
end

@testset "Issue" begin
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
        "html_url": "https://github.com/octocat/Hello-World/pull/1347"
      },
      "locked": false,
      "closed_at": null,
      "created_at": "2011-04-22T13:33:48Z"
    }
    """
    )

    issue_result = Issue(
        Nullable{Int}(),
        Nullable{Int}(Int(issue_json["number"])),
        Nullable{Int}(),
        Nullable{String}(String(issue_json["title"])),
        Nullable{String}(),
        Nullable{String}(),
        Nullable{Owner}(Owner(issue_json["user"])),
        Nullable{Owner}(),
        Nullable{Owner}(),
        Nullable{Dates.DateTime}(Dates.DateTime(chop(issue_json["created_at"]))),
        Nullable{Dates.DateTime}(),
        Nullable{Dates.DateTime}(),
        Nullable{Vector{Dict}}(Vector{Dict}(issue_json["labels"])),
        Nullable{Dict}(),
        Nullable{PullRequest}(PullRequest(issue_json["pull_request"])),
        Nullable{HttpCommon.URI}(HttpCommon.URI(issue_json["url"])),
        Nullable{HttpCommon.URI}(),
        Nullable{HttpCommon.URI}(),
        Nullable{HttpCommon.URI}(),
        Nullable{HttpCommon.URI}(),
        Nullable{Bool}(Bool(issue_json["locked"]))
    )

    @test Issue(issue_json) == issue_result
    @test name(Issue(issue_json["number"])) == name(issue_result)
    @test setindex!(GitHub.github2json(issue_result), nothing, "closed_at") == issue_json

    test_show(issue_result)
end

@testset "Team" begin
    team_json = JSON.parse("""
      {
        "id": 1,
        "url": "https://api.github.com/teams/1",
        "name": "Justice League",
        "slug": "justice-league",
        "description": "A great team.",
        "privacy": "closed",
        "permission": "admin",
        "members_url": "https://api.github.com/teams/1/members{/member}",
        "repositories_url": "https://api.github.com/teams/1/repos"
      }
    """)

    team_result = Team(
        Nullable{String}(team_json["name"]),
        Nullable{String}(team_json["description"]),
        Nullable{String}(team_json["privacy"]),
        Nullable{String}(team_json["permission"]),
        Nullable{String}(team_json["slug"]),
        Nullable{Int}(Int(team_json["id"])))

    @test name(team_result) == Int(team_json["id"])
    test_show(team_result)
end

@testset "Gist" begin
    gist_json = JSON.parse("""
      {
        "url": "https://api.github.com/gists/aa5a315d61ae9438b18d",
        "forks_url": "https://api.github.com/gists/aa5a315d61ae9438b18d/forks",
        "commits_url": "https://api.github.com/gists/aa5a315d61ae9438b18d/commits",
        "id": "aa5a315d61ae9438b18d",
        "description": "description of gist",
        "public": true,
        "owner": {
          "login": "octocat",
          "id": 1,
          "gravatar_id": "",
          "url": "https://api.github.com/users/octocat",
          "type": "User",
          "site_admin": false
        },
        "user": null,
        "files": {
          "ring.erl": {
            "size": 932,
            "raw_url": "https://gist.githubusercontent.com/raw/365370/8c4d2d43d178df44f4c03a7f2ac0ff512853564e/ring.erl",
            "type": "text/plain",
            "language": "Erlang",
            "truncated": false,
            "content": "contents of gist"
          }
        },
        "truncated": false,
        "comments": 0,
        "comments_url": "https://api.github.com/gists/aa5a315d61ae9438b18d/comments/",
        "html_url": "https://gist.github.com/aa5a315d61ae9438b18d",
        "git_pull_url": "https://gist.github.com/aa5a315d61ae9438b18d.git",
        "git_push_url": "https://gist.github.com/aa5a315d61ae9438b18d.git",
        "created_at": "2010-04-14T02:15:15Z",
        "updated_at": "2011-06-20T11:34:15Z",
        "forks": [
          {
            "user": {
              "login": "octocat",
              "id": 1,
              "gravatar_id": "",
              "url": "https://api.github.com/users/octocat",
              "site_admin": false
            },
            "url": "https://api.github.com/gists/dee9c42e4998ce2ea439",
            "id": "dee9c42e4998ce2ea439",
            "created_at": "2011-04-14T16:00:49Z",
            "updated_at": "2011-04-14T16:00:49Z"
          }
        ],
        "history": [
          {
            "url": "https://api.github.com/gists/aa5a315d61ae9438b18d/57a7f021a713b1c5a6a199b54cc514735d2d462f",
            "version": "57a7f021a713b1c5a6a199b54cc514735d2d462f",
            "user": {
              "login": "octocat",
              "id": 1,
              "avatar_url": "https://github.com/images/error/octocat_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/octocat",
              "html_url": "https://github.com/octocat",
              "followers_url": "https://api.github.com/users/octocat/followers",
              "following_url": "https://api.github.com/users/octocat/following{/other_user}",
              "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
              "organizations_url": "https://api.github.com/users/octocat/orgs",
              "repos_url": "https://api.github.com/users/octocat/repos",
              "events_url": "https://api.github.com/users/octocat/events{/privacy}",
              "received_events_url": "https://api.github.com/users/octocat/received_events",
              "type": "User",
              "site_admin": false
            },
            "change_status": {
              "deletions": 0,
              "additions": 180,
              "total": 180
            },
            "committed_at": "2010-04-14T02:15:15Z"
          }
        ]
      }
      """
    )

    gist_result = Gist(
      Nullable{HttpCommon.URI}(HttpCommon.URI(gist_json["url"])),
      Nullable{HttpCommon.URI}(HttpCommon.URI(gist_json["forks_url"])),
      Nullable{HttpCommon.URI}(HttpCommon.URI(gist_json["commits_url"])),
      Nullable{String}(gist_json["id"]),
      Nullable{String}(gist_json["description"]),
      Nullable{Bool}(gist_json["public"]),
      Nullable{Owner}(Owner(gist_json["owner"])),
      Nullable{Owner}(),
      Nullable{Bool}(gist_json["truncated"]),
      Nullable{Int}(gist_json["comments"]),
      Nullable{HttpCommon.URI}(HttpCommon.URI(gist_json["comments_url"])),
      Nullable{HttpCommon.URI}(HttpCommon.URI(gist_json["html_url"])),
      Nullable{HttpCommon.URI}(HttpCommon.URI(gist_json["git_pull_url"])),
      Nullable{HttpCommon.URI}(HttpCommon.URI(gist_json["git_push_url"])),
      Nullable{Dates.DateTime}(Dates.DateTime(chop(gist_json["created_at"]))),
      Nullable{Dates.DateTime}(Dates.DateTime(chop(gist_json["updated_at"]))),
      Nullable{Vector{Gist}}(map(Gist, gist_json["forks"])),
      Nullable{Dict}(gist_json["files"]),
      Nullable{Vector{Dict}}(gist_json["history"]),
    )

    @test Gist(gist_json) == gist_result
    @test name(Gist(gist_json["id"])) == name(gist_result)
    @test setindex!(GitHub.github2json(gist_result), nothing, "user") == gist_json

    test_show(gist_result)
end