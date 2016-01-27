# GitHub.jl

[![GitHub](http://pkg.julialang.org/badges/GitHub_0.4.svg)](http://pkg.julialang.org/?pkg=GitHub)
[![GitHub](http://pkg.julialang.org/badges/GitHub_0.5.svg)](http://pkg.julialang.org/?pkg=GitHub)
[![Build Status](https://travis-ci.org/JuliaWeb/GitHub.jl.svg?branch=master)](https://travis-ci.org/JuliaWeb/GitHub.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/gmlm8snv03aw5pwq/branch/master?svg=true)](https://ci.appveyor.com/project/jrevels/github-jl-lj49i/branch/master)
[![Coverage Status](https://coveralls.io/repos/JuliaWeb/GitHub.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaWeb/GitHub.jl?branch=master)

GitHub.jl provides a Julia interface to the [GitHub API v3](https://developer.github.com/v3/). Using GitHub.jl, you can do things like:

- query for basic repository, organization, and user information
- programmatically take user-level actions (e.g. starring a repository, commenting on an issue, etc.)
- set up listeners that can detect and respond to repository events
- create and retrieve commit statuses (i.e. report CI pending/failure/success statuses to GitHub)

Here's a table of contents for this rather lengthy README:

[1. Response Types](#response-types)

[2. REST Methods](#rest-methods)

[3. Authentication](#authentication)

[4. Pagination](#pagination)

[5. Handling Webhook Events](#handling-webhook-events)

## Response Types

GitHub's JSON responses are parsed and returned to the caller as types of the form `G<:GitHub.GitHubType`. Here's some useful information about these types:

- All fields are `Nullable`.
- Field names generally match the corresponding field in GitHub's JSON representation (the exception is `"type"`, which has the corresponding field name `typ` to avoid the obvious language conflict).
- `GitHubType`s can be passed as arguments to API methods in place of (and in combination with) regular identifying properties. For example, `create_status(repo, commit)` could be called as:

   - `create_status(::GitHub.Repo, ::GitHub.Commit)`
   - `create_status(::GitHub.Repo, ::AbstractString)` where the second argument is the SHA
   - `create_status(::AbstractString, ::GitHub.Commit)` where the first argument is the full qualified repo name
   - `create_status(::AbstractString, ::AbstractString)` where the first argument is the repo name, and the second is the SHA

Here's a table that matches up the provided `GitHubType`s with their corresponding API documentation, as well as alternative identifying values:

| type          | alternative identifying property                       | link(s) to documentation                                                                                                                                                                                      |
|---------------|--------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Owner`       | login, e.g. `"octocat"`                                | [organizations](https://developer.github.com/v3/orgs/), [users](https://developer.github.com/v3/users/)                                                                                                       |
| `Repo`        | full_name, e.g. `"JuliaWeb/GitHub.jl"`                 | [repositories](https://developer.github.com/v3/repos/)                                                                                                                                                        |
| `Commit`      | sha, e.g. `"d069993b320c57b2ba27336406f6ec3a9ae39375"` | [repository commits](https://developer.github.com/v3/repos/commits/)                                                                                                                                          |
| `Branch`      | name, e.g. `master`                                    | [repository branches](https://developer.github.com/v3/repos/#get-branch)                                                                                                                                      |
| `Content`     | path, e.g. `"src/owners/owners.jl"`                    | [repository contents](https://developer.github.com/v3/repos/contents/)                                                                                                                                        |
| `Comment`     | id, e.g. `162224613`                                   | [commit comments](https://developer.github.com/v3/repos/comments/), [issue comments](https://developer.github.com/v3/issues/comments/), [PR review comments](https://developer.github.com/v3/pulls/comments/) |
| `Status`      | id, e.g. `366961773`                                   | [commit statuses](https://developer.github.com/v3/repos/statuses/)                                                                                                                                            |
| `PullRequest` | number, e.g. `44`                                      | [pull requests](https://developer.github.com/v3/pulls/)                                                                                                                                                       |
| `Issue`       | number, e.g. `31`                                      | [issues](https://developer.github.com/v3/issues/)                                                                                                                                                             |

You can inspect which fields are available for a type `G<:GitHubType` by calling `fieldnames(G)`.

## REST Methods

GitHub.jl implements a bunch of methods that make REST requests to GitHub's API. The below sections list these methods (note that a return type of `Tuple{Vector{T}, Dict}` means the result is [paginated](#pagination)).

#### Users and Organizations

| method                                   | return type                        | documentation                                                                                                                                                                                               |
|------------------------------------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `owner(owner[, isorg = false])`          | `Owner`                            | get `owner` as a [user](https://developer.github.com/v3/users/#get-a-single-user) or [organization](https://developer.github.com/v3/orgs/#get-an-organization)                                                    |
| `orgs(owner)`                            | `Tuple{Vector{Owner}, Dict}`       | [get the `owner`'s organizations](https://developer.github.com/v3/orgs/#list-user-organizations)                                                                                                            |
| `followers(owner)`                       | `Tuple{Vector{Owner}, Dict}`       | [get the `owner`'s followers](https://developer.github.com/v3/users/followers/#list-followers-of-a-user)                                                                                                    |
| `following(owner)`                       | `Tuple{Vector{Owner}, Dict}`       | [get the users followed by `owner`](https://developer.github.com/v3/users/followers/#list-users-followed-by-another-user)                                                                                   |
| `repos(owner[, isorg = false])`          | `Tuple{Vector{Repo}, Dict}`        | [get the `owner`'s repositories](https://developer.github.com/v3/repos/#list-user-repositories)/[get an organization's repositories](https://developer.github.com/v3/repos/#list-organization-repositories) |

#### Repositories

| method                                   | return type                        | documentation                                                                                                                                                                                               |
|------------------------------------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `repo(repo)`                             | `Repo`                             | [get `repo`](https://developer.github.com/v3/repos/#get)                                                                                                                                                    |
| `create_fork(repo)`                      | `Repo`                             | [create a fork of `repo`](https://developer.github.com/v3/repos/forks/#create-a-fork)                                                                                                                       |
| `forks(repo)`                            | `Tuple{Vector{Repo}, Dict}`        | [get `repo`'s forks](https://developer.github.com/v3/repos/forks/#list-forks)                                                                                                                               |
| `contributors(repo)`                     | `Dict`                             | [get `repo`'s contributors](https://developer.github.com/v3/repos/#list-contributors)                                                                                                                       |
| `collaborators(repo)`                    | `Tuple{Vector{Owner}, Dict}`       | [get `repo`'s collaborators](https://developer.github.com/v3/repos/collaborators/#list)                                                                                                                     |
| `iscollaborator(repo, user)`             | `Bool`                             | [check if `user` is a collaborator on `repo`](https://developer.github.com/v3/repos/collaborators/#get)                                                                                                     |
| `add_collaborator(repo, user)`           | `HttpCommon.Response`              | [add `user` as a collaborator to `repo`](https://developer.github.com/v3/repos/collaborators/#add-collaborator)                                                                                             |
| `remove_collaborator(repo, user)`        | `HttpCommon.Response`              | [remove `user` as a collaborator from `repo`](https://developer.github.com/v3/repos/collaborators/#remove-collaborator)                                                                                     |
| `stats(repo, stat[, attempts = 3])`      | `HttpCommon.Response`              | [get information on `stat` (e.g. "contributors", "code_frequency", "commit_activity", etc.)](https://developer.github.com/v3/repos/statistics/)                                                             |
| `commit(repo, sha)`                      | `Commit`                           | [get the commit specified by `sha`](https://developer.github.com/v3/repos/commits/#get-a-single-commit)                                                                                                     |
| `commits(repo)`                          | `Tuple{Vector{Commit}, Dict}`      | [get `repo`'s commits](https://developer.github.com/v3/repos/commits/#list-commits-on-a-repository)                                                                                                         |
| `branch(repo, branch)`                   | `Branch`                           | [get the branch specified by `branch`](https://developer.github.com/v3/repos/#get-branch)                                                                                                                   |
| `branches(repo)`                         | `Tuple{Vector{Branch}, Dict}`      | [get `repo`'s branches](https://developer.github.com/v3/repos/#list-branches)                                                                                                                               |
| `file(repo, path)`                       | `Content`                          | [get the file specified by `path`](https://developer.github.com/v3/repos/contents/#get-contents)                                                                                                            |
| `directory(repo, path)`                  | `Tuple{Vector{Content}, Dict}`     | [get the contents of the directory specified by `path`](https://developer.github.com/v3/repos/contents/#get-contents)                                                                                       |
| `create_file(repo, path)`                | `Dict`                             | [create a file at `path` in `repo`](https://developer.github.com/v3/repos/contents/#create-a-file)                                                                                                          |
| `update_file(repo, path)`                | `Dict`                             | [update a file at `path` in `repo`](https://developer.github.com/v3/repos/contents/#update-a-file)                                                                                                          |
| `delete_file(repo, path)`                | `Dict`                             | [delete a file at `path` in `repo`](https://developer.github.com/v3/repos/contents/#delete-a-file)                                                                                                          |
| `readme(repo)`                           | `Content`                          | [get `repo`'s README](https://developer.github.com/v3/repos/contents/#get-the-readme)                                                                                                                       |
| `create_status(repo, sha)`               | `Status`                           | [create a status for the commit specified by `sha`](https://developer.github.com/v3/repos/statuses/#create-a-status)                                                                                        |
| `statuses(repo, ref)`                    | `Tuple{Vector{Status}, Dict}`      | [get the statuses posted to `ref`](https://developer.github.com/v3/repos/statuses/#list-statuses-for-a-specific-ref)                                                                                        |
| `status(repo, ref)`                      | `Status`                           | [get the combined status for `ref`](https://developer.github.com/v3/repos/statuses/#get-the-combined-status-for-a-specific-ref)                                                                             |

#### Pull Requests and Issues

| method                                   | return type                        | documentation                                                                                                                                                                                               |
|------------------------------------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `pull_request(repo, pr)`                 | `PullRequest`                      | [get the pull request specified by `pr`](https://developer.github.com/v3/pulls/#get-a-single-pull-request)                                                                                                  |
| `pull_requests(repo)`                    | `Tuple{Vector{PullRequest}, Dict}` | [get `repo`'s pull requests](https://developer.github.com/v3/pulls/#list-pull-requests)                                                                                                                     |
| `issue(repo, issue)`                     | `Issue`                            | [get the issue specified by `issue`](https://developer.github.com/v3/issues/#get-a-single-issue)                                                                                                            |
| `issues(repo)`                           | `Tuple{Vector{Issue}, Dict}`       | [get `repo`'s issues](https://developer.github.com/v3/issues/#list-issues-for-a-repository)                                                                                                                 |
| `create_issue(repo)`                     | `Issue`                            | [create an issue in `repo`](https://developer.github.com/v3/issues/#create-an-issue)                                                                                                                        |
| `edit_issue(repo, issue)`                | `Issue`                            | [edit `issue` in `repo`](https://developer.github.com/v3/issues/#edit-an-issue)                                                                                                                             |

#### Comments

| method                                   | return type                        | documentation                                                                                                                                                                                               |
|------------------------------------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `comment(repo, comment, :issue)`         | `Comment`                          | [get an issue `comment` from `repo`](https://developer.github.com/v3/issues/comments/#get-a-single-comment)                                                                                                 |
| `comment(repo, comment, :pr)`            | `Comment`                          | [get a PR `comment` from `repo`](https://developer.github.com/v3/issues/comments/#get-a-single-comment)                                                                                                     |
| `comment(repo, comment, :review)`        | `Comment`                          | [get an review `comment` from `repo`](https://developer.github.com/v3/pulls/comments/#get-a-single-comment)                                                                                                 |
| `comment(repo, comment, :commit)`        | `Comment`                          | [get a commit `comment` from `repo`](https://developer.github.com/v3/repos/comments/#get-a-single-commit-comment)                                                                                           |
| `comments(repo, issue, :issue)`          | `Tuple{Vector{Comment}, Dict}`     | [get the comments on `issue` in `repo`](https://developer.github.com/v3/issues/comments/#list-comments-on-an-issue)                                                                                         |
| `comments(repo, pr, :pr)`                | `Tuple{Vector{Comment}, Dict}`     | [get the comments on `pr` in `repo`](https://developer.github.com/v3/issues/comments/#list-comments-on-an-issue)                                                                                            |
| `comments(repo, pr, :review)`            | `Tuple{Vector{Comment}, Dict}`     | [get the review comments on `pr` in `repo`](https://developer.github.com/v3/pulls/comments/#list-comments-on-a-pull-request)                                                                                |
| `comments(repo, commit, :commit)`        | `Tuple{Vector{Comment}, Dict}`     | [get the comments on `commit` in `repo`](https://developer.github.com/v3/repos/comments/#list-comments-for-a-single-commit)                                                                                 |
| `create_comment(repo, issue, :issue)`    | `Comment`                          | [create a comment on `issue` in `repo`](https://developer.github.com/v3/issues/comments/#create-a-comment)                                                                                                  |
| `create_comment(repo, pr, :pr)`          | `Comment`                          | [create a comment on `pr` in `repo`](https://developer.github.com/v3/issues/comments/#create-a-comment)                                                                                                     |
| `create_comment(repo, pr, :review)`      | `Comment`                          | [create a review comment on `pr` in `repo`](https://developer.github.com/v3/pulls/comments/#create-a-comment)                                                                                               |
| `create_comment(repo, commit, :commit)`  | `Comment`                          | [create a comment on `commit` in `repo`](https://developer.github.com/v3/repos/comments/#create-a-commit-comment)                                                                                           |
| `edit_comment(repo, comment, :issue)`    | `Comment`                          | [edit the issue `comment` in `repo`](https://developer.github.com/v3/issues/comments/#edit-a-comment)                                                                                                       |
| `edit_comment(repo, comment, :pr)`       | `Comment`                          | [edit the PR `comment` in `repo`](https://developer.github.com/v3/issues/comments/#edit-a-comment)                                                                                                          |
| `edit_comment(repo, comment, :review)`   | `Comment`                          | [edit the review `comment` in `repo`](https://developer.github.com/v3/pulls/comments/#edit-a-comment)                                                                                                       |
| `edit_comment(repo, comment, :commit)`   | `Comment`                          | [edit the commit `comment` in `repo`](https://developer.github.com/v3/repos/comments/#update-a-commit-comment)                                                                                              |
| `delete_comment(repo, comment, :issue)`  | `HttpCommon.Response`              | [delete the issue `comment` from `repo`](https://developer.github.com/v3/issues/comments/#delete-a-comment)                                                                                                 |
| `delete_comment(repo, comment, :pr)`     | `HttpCommon.Response`              | [delete the PR `comment` from `repo`](https://developer.github.com/v3/issues/comments/#delete-a-comment)                                                                                                    |
| `delete_comment(repo, comment, :review)` | `HttpCommon.Response`              | [delete the review `comment` from `repo`](https://developer.github.com/v3/pulls/comments/#delete-a-comment)                                                                                                 |
| `delete_comment(repo, comment, :commit)` | `HttpCommon.Response`              | [delete the commit`comment` from `repo`](https://developer.github.com/v3/repos/comments/#delete-a-commit-comment)                                                                                           |

#### Social Activity

| method                                   | return type                        | documentation                                                                                                                                                                                               |
|------------------------------------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `star(repo)`                             | `HttpCommon.Response`              | [star `repo`](https://developer.github.com/v3/activity/starring/#star-a-repository)                                                                                                                         |
| `unstar(repo)`                           | `HttpCommon.Response`              | [unstar `repo`](https://developer.github.com/v3/activity/starring/#unstar-a-repository)                                                                                                                     |
| `stargazers(repo)`                       | `Tuple{Vector{Owner}, Dict}`       | [get `repo`'s stargazers](https://developer.github.com/v3/activity/starring/#list-stargazers)                                                                                                               |
| `starred(user)`                          | `Tuple{Vector{Repo}, Dict}`        | [get repositories starred by `user`](https://developer.github.com/v3/activity/starring/#list-repositories-being-starred)                                                                                    |
| `watchers(repo)`                         | `Tuple{Vector{Owner}, Dict}`       | [get `repo`'s watchers](https://developer.github.com/v3/activity/watching/#list-watchers)                                                                                                                   |
| `watched(user)`                          | `Tuple{Vector{Repo}, Dict}`        | [get repositories watched by `user`](https://developer.github.com/v3/activity/watching/#list-repositories-being-watched)                                                                                    |
| `watch(repo)`                            | `HttpCommon.Response`              | [watch `repo`](https://developer.github.com/v3/activity/watching/#set-a-repository-subscription)                                                                                                            |
| `unwatch(repo)`                          | `HttpCommon.Response`              | [unwatch `repo`](https://developer.github.com/v3/activity/watching/#delete-a-repository-subscription)                                                                                                       |

#### Miscellaneous

| method                                   | return type                        | documentation                                                                                                                                                                                               |
|------------------------------------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `rate_limit()`                           | `Dict`                             | [get your rate limit status](https://developer.github.com/v3/rate_limit/#get-your-current-rate-limit-status)                                                                                                |
| `authenticate(token)`                    | `OAuth2`                           | [validate `token` and return an authentication object](https://developer.github.com/v3/#authentication)                                                                                                     |

#### Keyword Arguments

All REST methods accept the following keyword arguments:

| keyword        | type                    | default value            | description                                                                                    |
|----------------|-------------------------|--------------------------|------------------------------------------------------------------------------------------------|
| `auth`         | `GitHub.Authorization`  | `GitHub.AnonymousAuth()` | The request's authorization                                                                    |
| `params`       | `Dict`                  | `Dict()`                 | The request's query parameters                                                                 |
| `headers`      | `Dict`                  | `Dict()`                 | The request's headers. Note that these headers will be mutated by GitHub.jl request methods.   |
| `handle_error` | `Bool`                  | `true`                   | If `true`, a Julia error will be thrown in the event that GitHub's response reports an error.  |
| `page_limit`   | `Real`                  | `Inf`                    | The number of pages to return (only applies to paginated results, obviously)                   |

## Authentication

To authenticate your requests to GitHub, you'll need to generate an appropriate [access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use). Then, you can do stuff like the following (this example assumes that you set an environmental variable `GITHUB_AUTH` containing the access token):

```julia
import GitHub
myauth = GitHub.authenticate(ENV["GITHUB_AUTH"]) # don't hardcode your access tokens!
GitHub.star("JuliaWeb/GitHub.jl"; auth = myauth)  # star the GitHub.jl repo as the user identified by myauth
```

As you can see, you can propagate the identity/permissions of the `myauth` token to GitHub.jl's methods by passing `auth = myauth` as a keyword argument.

Note that if authentication is not provided, they'll be subject to the restrictions GitHub imposes on unauthenticated requests (such as [stricter rate limiting](https://developer.github.com/v3/#rate-limiting))

## Pagination

GitHub will often [paginate](https://developer.github.com/v3/#pagination) results for requests that return multiple items. On the GitHub.jl side of things, it's pretty easy to see which methods return paginated results by referring to the [REST Methods documentation](#rest-methods); if a method returns a `Tuple{Vector{T}, Dict}`, that means its results are paginated.

Paginated methods return both the response values, and some pagination metadata. You can use the `per_page`/`page` query parameters and the `page_limit` keyword argument to configure result pagination.

For example, let's request a couple pages of GitHub.jl's PRs, and configure our result pagination to see how it works:

```julia
julia> myparams = Dict("state" => "all", "per_page" => 3, "page" => 2); # show all PRs (both open and closed), and give me 3 items per page starting at page 2

julia> prs, page_data = pull_requests("JuliaWeb/GitHub.jl"; params = myparams, page_limit = 2);

julia> prs # 3 items per page * 2 page limit == 6 items, as expected
6-element Array{GitHub.PullRequest,1}:
 GitHub.PullRequest(39)
 GitHub.PullRequest(38)
 GitHub.PullRequest(37)
 GitHub.PullRequest(34)
 GitHub.PullRequest(32)
 GitHub.PullRequest(30)

julia> page_data
Dict{UTF8String,Int64} with 3 entries:
  "last"  => 5
  "left"  => 2
  "next"  => 4
```

In the above, `prs` contains the results from page 2 and 3. We know this because we specified page 2 as our starting page (`"page" => 2`), and limited the response to 2 pages max (`page_limit = 2`). In addition, we know that exactly 2 pages were actually retrieved, since there are 6 items and we said each page should only contain 3 items (`"per_page" => 3`).

The values provided by `page_data` are calculated by assuming the same `per_page` value given in the original request. Here's a description of each key in `page_data`:

- `page_data["last"]`: The last page of results available to be queried. In our example, the final page we could query for is page 5.
- `page_data["left"]`: The number of pages left between the final page delivered in our result and `page_data["last"]`. Our final page was page 3, and the last page is page 5, so we have 2 pages of results left to retrieve.
- `page_data["next"]`: The index of the next page after the final page delivered in our result. In the example, our final page was page 3, so the next page will be 4.

## Handling Webhook Events

GitHub.jl comes with configurable `EventListener` and `CommentListener` types that can be used as basic servers for parsing and responding to events delivered by [GitHub's repository Webhooks](https://developer.github.com/webhooks/).

#### `EventListener`

When an `EventListener` receives an event, it performs some basic validation and wraps the event payload (and some other data) in [a `WebhookEvent` type](https://github.com/JuliaWeb/GitHub.jl/blob/master/src/activity/events/events.jl). This `WebhookEvent` instance, along with the provided `Authorization`, is then fed to the server's handler function, which the user defines to determine the server's response behavior. The handler function is expected to return an `HttpCommon.Response` that is then sent back to GitHub.

The `EventListener` constructor takes the following keyword arguments:

- `auth`: GitHub authorization (usually with repo-level permissions).
- `secret`: A string used to verify the event source. If the event is from a GitHub Webhook, it's the Webhook's secret. If a secret is not provided, the server won't validate the secret signature of incoming requests.
- `repos`: A vector of `Repo`s (or fully qualified repository names) listing all acceptable repositories. All repositories are whitelisted by default.
- `events`: A vector of [event names](https://developer.github.com/webhooks/#events) listing all acceptable events (e.g. ["commit_comment", "pull_request"]). All events are whitelisted by default.
- `forwards`: A vector of `HttpCommon.URI`s (or URI strings) to which any incoming requests should be forwarded (after being validated by the listener)

Here's an example that demonstrates how to construct and run an `EventListener` that does benchmarking on every commit and PR:

```julia
import GitHub

# EventListener settings
myauth = GitHub.authenticate(ENV["GITHUB_AUTH"])
mysecret = ENV["MY_SECRET"]
myevents = ["pull_request", "push"]
myrepos = [GitHub.Repo("owner1/repo1"), "owner2/repo2"] # can be Repos or repo names
myforwards = [HttpCommon.URI("http://myforward1.com"), "http://myforward2.com"] # can be HttpCommon.URIs or URI strings

# Set up Status parameters
pending_params = Dict(
    "state" => "pending",
    "context" => "Benchmarker",
    "description" => "Running benchmarks..."
)

success_params = Dict(
    "state" => "success",
    "context" => "Benchmarker",
    "description" => "Benchmarks complete!"
)

error_params(err) = Dict(
    "state" => "error",
    "context" => "Benchmarker",
    "description" => "Error: $err"
)

# We can use Julia's `do` notation to set up the listener's handler function
listener = GitHub.EventListener(auth = myauth,
                                secret = mysecret,
                                repos = myrepos,
                                events = myevents,
                                forwards = myforwards) do event
    kind, payload, repo = event.kind, event.payload, event.repository

    if kind == "pull_request" && payload["action"] == "closed"
        return HttpCommon.Response(200)
    end

    if event.kind == "push"
        sha = event.payload["after"]
    elseif event.kind == "pull_request"
        sha = event.payload["pull_request"]["head"]["sha"]
    end

    GitHub.create_status(repo, sha; auth = myauth, params = pending_params)

    try
        # run_and_log_benchmarks isn't actually a defined function, but you get the point
        run_and_log_benchmarks(event, "\$(sha)-benchmarks.csv")
    catch err
        GitHub.create_status(repo, sha; auth = myauth, params = error_params(err))
        return HttpCommon.Response(500)
    end

    GitHub.create_status(repo, sha; auth = myauth, params = success_params)

    return HttpCommon.Response(200)
end

# Start the listener on localhost at port 8000
GitHub.run(listener, host=IPv4(127,0,0,1), port=8000)
```

#### `CommentListener`

A `CommentListener` is a special kind of `EventListener` that allows users to pass data to the listener's handler function via commenting. This is useful for triggering events on repositories that require configuration settings.

A `CommentListener` automatically filters out all non-comment events, and then checks each comment event it receives for a specific, user-defined "trigger phrase". The trigger phrase has the following structure:

```
`$trigger(args...)`
```

...where `args` can be anything. If the trigger phrase is found in a comment, then the `CommentListener` calls its handler function, passing it the event, the provided authentication, and `"(args...)"`.

The `CommentListener` constructor takes the following keyword arguments:

- `auth`: same as `EventListener`
- `secret`: same as `EventListener`
- `repos`: same as `EventListener`
- `forwards`: same as `EventListener`
- `check_collab`: If `true`, only acknowledge comments made by repository collaborators. Note that, if `check_collab` is `true`, `auth` must have the appropriate permissions to query the comment's repository for the collaborator status of the commenter. `check_collab` is `true` by default.

For example, let's set up a silly `CommentListener` that responds to the commenter with a greeting. To give a demonstration of the desired behavior, if a collaborator makes a comment like:

```
Man, I really would like to be greeted today.

`sayhello("Bob", "outgoing")`
```

We want the `CommentLister` to reply:

```
Hello, Bob, you look very outgoing today!
```

Here's the code that will make this happen:

```julia
import GitHub

# CommentListener settings
trigger = "sayhello"
myauth = GitHub.authenticate(ENV["GITHUB_AUTH"])
mysecret = ENV["MY_SECRET"]

# We can use Julia's `do` notation to set up the listener's handler function.
# Note that, in our example case, argstring will equal "(\"Bob\", \"outgoing\")".
listener = GitHub.CommentListener(trigger; auth = myauth, secret = mysecret) do event, argstring
    # In our example case, this code sets name to "Bob" and adjective to "outgoing"
    name, adjective = map(s -> strip(s)[2:(end-1)], split(argstring[2:(end-1)], ','))
    comment_params = Dict("body" => "Hello, $name, you look very $adjective today!")

    # Parse the original comment event for all the necessary reply info
    comment = GitHub.Comment(event.payload["comment"])

    if event.kind == "issue_comment"
        comment_kind = :issue
        reply_to = event.payload["issue"]["number"]
    elseif event.kind == "commit_comment"
        comment_kind = :commit
        reply_to = get(comment.commit_id)
    elseif event.kind == "pull_request_review_comment"
        comment_kind = :review
        reply_to = event.payload["pull_request"]["number"]
        # load required query params for review comment creation
        comment_params["commit_id"] = get(comment.commit_id)
        comment_params["path"] = get(comment.path)
        comment_params["position"] = get(comment.position)
    end

    # send the comment creation request to GitHub
    GitHub.create_comment(event.repository, reply_to, comment_kind; auth = myauth, params = comment_params)

    return HttpCommon.Response(200)
end

# Start the listener on localhost at port 8000
GitHub.run(listener, host=IPv4(127,0,0,1), port=8000)
```
