# This file tests various GitHubType constructors. To test for proper Nullable
# handling, most fields have been removed from the JSON samples used below.
# Sample fields were selected in order to cover the full range of type behavior,
# e.g. if the GitHubType has a few Union{Dates.DateTime, Nothing} fields, at least one
# of those fields should be present in the JSON sample.

function test_show(g::GitHub.GitHubType)
    tmpio = IOBuffer()
    show(tmpio, g)

    # basically trivial, but proves that things aren't completely broken
    @test repr(g) == String(take!(tmpio))

    tmpio = IOBuffer()
    show(IOContext(tmpio, :compact => true), g)

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
        nothing,
        nothing,
        nothing,
        String(owner_json["login"]),
        nothing,
        nothing,
        nothing,
        nothing,
        Int(owner_json["id"]),
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        HTTP.URI(owner_json["html_url"]),
        Dates.DateTime(chop(owner_json["updated_at"])),
        nothing,
        nothing,
        Bool(owner_json["hireable"]),
        nothing
    )

    owner_kw = Owner(
      id         = 1,
      html_url   = "https://github.com/octocat",
      login      = "octocat",
      updated_at = "2008-01-14T04:33:35Z",
      hireable   = false)

    @test Owner(owner_json) == owner_result
    @test Owner(owner_json) == owner_kw
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
        nothing,
        String(repo_json["full_name"]),
        nothing,
        nothing,
        nothing,
        Owner(repo_json["owner"]),
        Repo(repo_json["parent"]),
        nothing,
        Int(repo_json["id"]),
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        HTTP.URI(repo_json["url"]),
        nothing,
        nothing,
        Dates.DateTime(chop(repo_json["pushed_at"])),
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        Bool(repo_json["private"]),
        nothing,
        repo_json["permissions"]
    )

    repo_kw = Repo(
        id          = 1296269,
        owner       = Owner(login= "octocat"),
        parent      = Repo(name= "test-parent"),
        full_name   = "octocat/Hello-World",
        private     = false,
        url         = "https://api.github.com/repos/octocat/Hello-World",
        pushed_at   = "2011-01-26T19:06:43Z",
        permissions = Dict(
            "admin" => false,
            "push"  => false,
            "pull"  => true
        )
    )
    
    @test Repo(repo_json) == repo_result
    @test Repo(repo_json) == repo_kw
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
        String(commit_json["sha"]),
        nothing,
        Owner(commit_json["author"]),
        nothing,
        Commit(commit_json["commit"]),
        HTTP.URI(commit_json["url"]),
        nothing,
        nothing,
        map(Commit, commit_json["parents"]),
        commit_json["stats"],
        map(Content, commit_json["files"]),
        nothing
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
        String(branch_json["name"]),
        nothing,
        nothing,
        nothing,
        Commit(branch_json["commit"]),
        Owner(branch_json["user"]),
        Repo(branch_json["repo"]),
        nothing,
        branch_json["protection"]
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
        String(comment_json["body"]),
        nothing,
        nothing,
        nothing,
        nothing,
        Int(comment_json["id"]),
        nothing,
        nothing,
        nothing,
        Dates.DateTime(chop(comment_json["created_at"])),
        nothing,
        HTTP.URI(comment_json["url"]),
        nothing,
        nothing,
        nothing,
        Owner(comment_json["user"])
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
        String(content_json["type"]),
        nothing,
        nothing,
        String(content_json["path"]),
        nothing,
        nothing,
        nothing,
        nothing,
        HTTP.URI(content_json["url"]),
        nothing,
        nothing,
        nothing,
        content_json["size"]
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
        Int(status_json["id"]),
        nothing,
        nothing,
        String(status_json["description"]),
        nothing,
        nothing,
        HTTP.URI(status_json["url"]),
        nothing,
        Dates.DateTime(chop(status_json["created_at"])),
        nothing,
        Owner(status_json["creator"]),
        Repo(status_json["repository"]),
        map(Status, status_json["statuses"])
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
        nothing,
        Branch(pr_json["head"]),
        Int(pr_json["number"]),
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        String(pr_json["body"]),
        nothing,
        Dates.DateTime(chop(pr_json["created_at"])),
        nothing,
        nothing,
        nothing,
        HTTP.URI(pr_json["url"]),
        nothing,
        Owner(pr_json["assignee"]),
        nothing,
        nothing,
        pr_json["milestone"],
        nothing,
        nothing,
        nothing,
        pr_json["locked"]
    )

    @test PullRequest(pr_json) == pr_result
    @test name(PullRequest(pr_json["number"])) == name(pr_result)
    @test GitHub.github2json(pr_result) == pr_json

    test_show(pr_result)
end

@testset "PullRequestFile" begin
    prf_json = JSON.parse(
    """
    {
        "sha": "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391",
        "filename": "abc",
        "status": "added",
        "additions": 0,
        "deletions": 0,
        "changes": 0,
        "blob_url": "https://github.com/nkottary/Example.jl/blob/d0f13113dddaf6bdce58f98f210ae734e4dcd67f/abc",
        "raw_url": "https://github.com/nkottary/Example.jl/raw/d0f13113dddaf6bdce58f98f210ae734e4dcd67f/abc",
        "contents_url": "https://api.github.com/repos/nkottary/Example.jl/contents/abc?ref=d0f13113dddaf6bdce58f98f210ae734e4dcd67f"
    }
    """
    )

    prf_result = PullRequestFile(
        "https://github.com/nkottary/Example.jl/raw/d0f13113dddaf6bdce58f98f210ae734e4dcd67f/abc",
        "added",
        nothing,
        0,
        "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391",
        "abc",
        0,
        0,
        "https://github.com/nkottary/Example.jl/blob/d0f13113dddaf6bdce58f98f210ae734e4dcd67f/abc",
        "https://api.github.com/repos/nkottary/Example.jl/contents/abc?ref=d0f13113dddaf6bdce58f98f210ae734e4dcd67f"
    )

    @test PullRequestFile(prf_json) == prf_result
    @test name(PullRequestFile(prf_json["filename"])) == name(prf_result)
    @test GitHub.github2json(prf_result) == prf_json

    test_show(prf_result)
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
        nothing,
        Int(issue_json["number"]),
        nothing,
        String(issue_json["title"]),
        nothing,
        nothing,
        Owner(issue_json["user"]),
        nothing,
        nothing,
        Dates.DateTime(chop(issue_json["created_at"])),
        nothing,
        nothing,
        issue_json["labels"],
        nothing,
        PullRequest(issue_json["pull_request"]),
        HTTP.URI(issue_json["url"]),
        nothing,
        nothing,
        nothing,
        nothing,
        Bool(issue_json["locked"])
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
        team_json["name"],
        team_json["description"],
        team_json["privacy"],
        team_json["permission"],
        team_json["slug"],
        Int(team_json["id"]))

    @test name(team_result) == Int(team_json["id"])
    test_show(team_result)
end

@testset "Webhook" begin
    hook_json = JSON.parse("""
      {
        "id": 12625455,
        "url": "https://api.github.com/repos/user/Example.jl/hooks/12625455",
        "test_url": "https://api.github.com/repos/user/Example.jl/hooks/12625455/test",
        "ping_url": "https://api.github.com/repos/user/Example.jl/hooks/12625455/pings",
        "name": "web",
        "events": ["push", "pull_request"],
        "active": true,
        "updated_at": "2017-03-14T14:03:16Z",
        "created_at": "2017-03-14T14:03:16Z"
      }
    """)

    hook_result = Webhook(
        hook_json["id"],
        HTTP.URI(hook_json["url"]),
        HTTP.URI(hook_json["test_url"]),
        HTTP.URI(hook_json["ping_url"]),
        hook_json["name"],
        map(String, hook_json["events"]),
        hook_json["active"],
        nothing,
        Dates.DateTime(chop("2017-03-14T14:03:16Z")),
        Dates.DateTime(chop("2017-03-14T14:03:16Z")))

    @test Webhook(hook_json) == hook_result
    @test name(Webhook(hook_json["id"])) == name(hook_result)
    @test setindex!(GitHub.github2json(hook_result), "web", "name") == hook_json

    test_show(hook_result)
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
      HTTP.URI(gist_json["url"]),
      HTTP.URI(gist_json["forks_url"]),
      HTTP.URI(gist_json["commits_url"]),
      gist_json["id"],
      gist_json["description"],
      gist_json["public"],
      Owner(gist_json["owner"]),
      nothing,
      gist_json["truncated"],
      gist_json["comments"],
      HTTP.URI(gist_json["comments_url"]),
      HTTP.URI(gist_json["html_url"]),
      HTTP.URI(gist_json["git_pull_url"]),
      HTTP.URI(gist_json["git_push_url"]),
      Dates.DateTime(chop(gist_json["created_at"])),
      Dates.DateTime(chop(gist_json["updated_at"])),
      map(Gist, gist_json["forks"]),
      gist_json["files"],
      gist_json["history"],
    )

    @test Gist(gist_json) == gist_result
    @test name(Gist(gist_json["id"])) == name(gist_result)
    @test setindex!(GitHub.github2json(gist_result), nothing, "user") == gist_json

    test_show(gist_result)
end

@testset "Installation" begin
    # This is the format of an installation in the "installation event"
    installation_json = JSON.parse("""
      {
        "id": 42926,
        "account": {
          "login": "Keno",
          "id": 1291671,
          "avatar_url": "https://avatars1.githubusercontent.com/u/1291671?v=4",
          "gravatar_id": "",
          "url": "https://api.github.com/users/Keno",
          "html_url": "https://github.com/Keno",
          "followers_url": "https://api.github.com/users/Keno/followers",
          "following_url": "https://api.github.com/users/Keno/following{/other_user}",
          "gists_url": "https://api.github.com/users/Keno/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/Keno/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/Keno/subscriptions",
          "organizations_url": "https://api.github.com/users/Keno/orgs",
          "repos_url": "https://api.github.com/users/Keno/repos",
          "events_url": "https://api.github.com/users/Keno/events{/privacy}",
          "received_events_url": "https://api.github.com/users/Keno/received_events",
          "type": "User",
          "site_admin": false
        },
        "repository_selection": "selected",
        "access_tokens_url": "https://api.github.com/installations/42926/access_tokens",
        "repositories_url": "https://api.github.com/installation/repositories",
        "html_url": "https://github.com/settings/installations/42926",
        "app_id": 4123,
        "target_id": 1291671,
        "target_type": "User",
        "permissions": {
          "contents": "read",
          "metadata": "read",
          "pull_requests": "read"
        },
        "events": [
          "commit_comment",
          "pull_request",
          "push",
          "release"
        ],
        "created_at": 1501449845,
        "updated_at": 1501449845,
        "single_file_name": null
      }
    """)

    installation_result = Installation(installation_json)

    @test name(installation_result) == Int(installation_json["id"])
end

@testset "Apps" begin
    app_json = JSON.parse("""
      {
        "id": 1,
        "owner": {
          "login": "github",
          "id": 1,
          "url": "https://api.github.com/orgs/github",
          "repos_url": "https://api.github.com/orgs/github/repos",
          "events_url": "https://api.github.com/orgs/github/events",
          "hooks_url": "https://api.github.com/orgs/github/hooks",
          "issues_url": "https://api.github.com/orgs/github/issues",
          "members_url": "https://api.github.com/orgs/github/members{/member}",
          "public_members_url": "https://api.github.com/orgs/github/public_members{/member}",
          "avatar_url": "https://github.com/images/error/octocat_happy.gif",
          "description": "A great organization"
        },
        "name": "Super CI",
        "description": "",
        "external_url": "https://example.com",
        "html_url": "https://github.com/apps/super-ci",
        "created_at": "2017-07-08T16:18:44",
        "updated_at": "2017-07-08T16:18:44"
      }
    """)

    app_result = App(app_json)
    @test name(app_result) == Int(app_json["id"])
end

@testset "Review" begin
    review_json = JSON.parse("""
      {
        "id": 80,
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
        "body": "Here is the body for the review.",
        "commit_id": "ecdd80bb57125d7ba9641ffaa4d7d2c19d3f3091",
        "state": "APPROVED",
        "html_url": "https://github.com/octocat/Hello-World/pull/12#pullrequestreview-80",
        "pull_request_url": "https://api.github.com/repos/octocat/Hello-World/pulls/12",
        "_links": {
          "html": {
            "href": "https://github.com/octocat/Hello-World/pull/12#pullrequestreview-80"
          },
          "pull_request": {
            "href": "https://api.github.com/repos/octocat/Hello-World/pulls/12"
          }
        }
      }
    """)

    review_result = App(review_json)
    @test name(review_result) == Int(review_json["id"])
end

@testset "Blob" begin
    blob_json = JSON.parse("""
    {
      "content": "Q29udGVudCBvZiB0aGUgYmxvYg==\\n",
      "encoding": "base64",
      "url": "https://api.github.com/repos/octocat/example/git/blobs/3a0f86fb8db8eea7ccbb9a95f325ddbedfb25e15",
      "sha": "3a0f86fb8db8eea7ccbb9a95f325ddbedfb25e15",
      "size": 19
    }
    """)

    blob_result = Blob(blob_json)
    @test name(blob_result) == blob_json["sha"]
end

@testset "Git Commit" begin
    commit_json = JSON.parse("""
    {
      "sha": "7638417db6d59f3c431d3e1f261cc637155684cd",
      "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/7638417db6d59f3c431d3e1f261cc637155684cd",
      "author": {
        "date": "2014-11-07T22:01:45Z",
        "name": "Scott Chacon",
        "email": "schacon@gmail.com"
      },
      "committer": {
        "date": "2014-11-07T22:01:45Z",
        "name": "Scott Chacon",
        "email": "schacon@gmail.com"
      },
      "message": "added readme, because im a good github citizen",
      "tree": {
        "url": "https://api.github.com/repos/octocat/Hello-World/git/trees/691272480426f78a0138979dd3ce63b77f706feb",
        "sha": "691272480426f78a0138979dd3ce63b77f706feb"
      },
      "parents": [
        {
          "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/1acc419d4d6a9ce985db7be48c6349a0475975b5",
          "sha": "1acc419d4d6a9ce985db7be48c6349a0475975b5"
        }
      ],
      "verification": {
        "verified": false,
        "reason": "unsigned",
        "signature": null,
        "payload": null
      }
    }
    """)
    commit_result = GitCommit(commit_json)
    @test name(commit_result) == commit_json["sha"]
end

@testset "Reference" begin
    reference_json = JSON.parse("""
    {
      "ref": "refs/heads/featureA",
      "url": "https://api.github.com/repos/octocat/Hello-World/git/refs/heads/featureA",
      "object": {
        "type": "commit",
        "sha": "aa218f56b14c9653891f9e74264a383fa43fefbd",
        "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/aa218f56b14c9653891f9e74264a383fa43fefbd"
      }
    }
    """)

    reference_result = Reference(reference_json)
    @test name(reference_result) == "heads/featureA"
end

@testset "Tag" begin
    tag_json = JSON.parse("""
    {
      "tag": "v0.0.1",
      "sha": "940bd336248efae0f9ee5bc7b2d5c985887b16ac",
      "url": "https://api.github.com/repos/octocat/Hello-World/git/tags/940bd336248efae0f9ee5bc7b2d5c985887b16ac",
      "message": "initial version",
      "tagger": {
        "name": "Scott Chacon",
        "email": "schacon@gmail.com",
        "date": "2014-11-07T22:01:45Z"
      },
      "object": {
        "type": "commit",
        "sha": "c3d0be41ecbe669545ee3e94d31ed9a4bc91ee3c",
        "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/c3d0be41ecbe669545ee3e94d31ed9a4bc91ee3c"
      },
      "verification": {
        "verified": false,
        "reason": "unsigned",
        "signature": null,
        "payload": null
      }
    }
    """)

    tag_result = Tag(tag_json)
    @test name(tag_result) == tag_json["sha"]
end

@testset "Tree" begin
    tree_json = JSON.parse("""
    {
      "sha": "9fb037999f264ba9a7fc6274d15fa3ae2ab98312",
      "url": "https://api.github.com/repos/octocat/Hello-World/trees/9fb037999f264ba9a7fc6274d15fa3ae2ab98312",
      "tree": [
        {
          "path": "file.rb",
          "mode": "100644",
          "type": "blob",
          "size": 30,
          "sha": "44b4fc6d56897b048c772eb4087f854f46256132",
          "url": "https://api.github.com/repos/octocat/Hello-World/git/blobs/44b4fc6d56897b048c772eb4087f854f46256132"
        },
        {
          "path": "subdir",
          "mode": "040000",
          "type": "tree",
          "sha": "f484d249c660418515fb01c2b9662073663c242e",
          "url": "https://api.github.com/repos/octocat/Hello-World/git/blobs/f484d249c660418515fb01c2b9662073663c242e"
        },
        {
          "path": "exec_file",
          "mode": "100755",
          "type": "blob",
          "size": 75,
          "sha": "45b983be36b73c0788dc9cbcb76cbb80fc7bb057",
          "url": "https://api.github.com/repos/octocat/Hello-World/git/blobs/45b983be36b73c0788dc9cbcb76cbb80fc7bb057"
        }
      ],
      "truncated": false
    }
    """)

    tree_result = Tree(tree_json)
    @test name(tree_result) == tree_json["sha"]
end

@testset "Release" begin
    release_json = JSON.parse("""
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/releases/1",
      "html_url": "https://github.com/octocat/Hello-World/releases/v1.0.0",
      "assets_url": "https://api.github.com/repos/octocat/Hello-World/releases/1/assets",
      "upload_url": "https://uploads.github.com/repos/octocat/Hello-World/releases/1/assets{?name,label}",
      "tarball_url": "https://api.github.com/repos/octocat/Hello-World/tarball/v1.0.0",
      "zipball_url": "https://api.github.com/repos/octocat/Hello-World/zipball/v1.0.0",
      "id": 1,
      "node_id": "MDc6UmVsZWFzZTE=",
      "tag_name": "v1.0.0",
      "target_commitish": "master",
      "name": "v1.0.0",
      "body": "Description of the release",
      "draft": false,
      "prerelease": false,
      "created_at": "2013-02-27T19:35:32Z",
      "published_at": "2013-02-27T19:35:32Z",
      "author": {
        "login": "octocat",
        "id": 1,
        "node_id": "MDQ6VXNlcjE=",
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
      "assets": [
      ]
    }
    """)

    release_result = Release(release_json)
    @test name(release_result) == release_json["id"]
end
