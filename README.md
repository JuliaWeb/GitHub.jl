## Octokit.jl

##### A Julia package targeting the GitHub API (v3)

[![Build Status](https://travis-ci.org/WestleyArgentum/Octokit.jl.png?branch=master)](https://travis-ci.org/WestleyArgentum/Octokit.jl)

### Installation

```julia
julia> Pkg.clone("https://github.com/WestleyArgentum/Octokit.jl.git")
```

### API

#### Authentication

All API methods accept a named parameter `auth` of type `Octokit.Authorization`. By default, this parameter will be an instance of `AnonymousAuth`, and the API request will be made without any privileges.

If you would like to make requests as an authorized user, you need to `authenticate`.

```julia
authenticate(token::String)
```
- `token` is an "application token" which you can [read about generating here](https://help.github.com/articles/creating-an-access-token-for-command-line-use)


#### Users

The `User` type is used to represent GitHub accounts. It contains lots of interesting information about an account, and can be used in other API requests.

```julia
user(username; auth = AnonymousAuth())
```
- `username` is the GitHub login
- if you provide `auth` potentially much more user information will be returned

```julia
followers(user::String)
followers(user::User)
```
```julia
following(user::String)
following(user::User)
```
- `user` is either a GitHub login or `User` type
- the returned data will be an array of `User` types


#### Organizations

Organizations let multiple users manage repositories together.

```julia
org(name; auth = AnonymousAuth())
```
- `name` is the GitHub organization login name

```julia
orgs(user::String; auth = AnonymousAuth())
```
- `user` is the GitHub account about which you are curious


#### Statistics

Repository statistics are interesting bits of information about activity. GitHub caches this data when possible, but sometimes a request will trigger regeneration and come back empty. For this reason all statistics functions have an argument `attempts` which will be the number of tries made before admitting defeat.

```julia
contributors(owner, repo, attempts = 3; auth = AnonymousAuth())
```
```julia
commit_activity(owner, repo, attempts = 3; auth = AnonymousAuth())
```
```julia
code_frequency(owner, repo, attempts = 3; auth = AnonymousAuth())
```
```julia
participation(owner, repo, attempts = 3; auth = AnonymousAuth())
```
```julia
punch_card(owner, repo, attempts = 3; auth = AnonymousAuth())
```
- `owner` is a GitHub login
- `repo` is a repository name
- `attempts` is the number of tries made before admitting defeat


#### Collaborators

Collaborators are users that work together and share access to repositories.

```julia
collaborators(owner, repo; auth = AnonymousAuth())
```
```julia
iscollaborator(owner, repo, user; auth = AnonymousAuth())
```
```julia
add_collaborator(owner, repo, user; auth = AnonymousAuth()
```
```julia
remove_collaborator(owner, repo, user; auth = AnonymousAuth())
```
- `owner` is a GitHub login
- `repo` is a repository name
- `user` is the GitHub login being inspected, added, or removed


#### Forks

```julia
forks(owner, repo; auth = AnonymousAuth())
```
```julia
fork(owner, repo, organization = ""; auth = AnonymousAuth())
```
- `owner` is a GitHub login
- `repo` is a repository name


#### Starring

```julia
stargazers(owner, repo; auth = AnonymousAuth())
```
```julia
starred(user; auth = AnonymousAuth())
```
```julia
star(owner, repo; auth = AnonymousAuth())
```
```julia
unstar(owner, repo; auth = AnonymousAuth())
```
- `owner` is a GitHub login
- `repo` is a repository name
- `user` is a GitHub login


#### Watching

```julia
watchers(owner, repo; auth = AnonymousAuth())
```
```julia
watched(user; auth = AnonymousAuth())
```
```julia
watching(owner, repo; auth = AnonymousAuth())
```
```julia
watch(owner, repo; auth = AnonymousAuth())
```
```julia
unwatch(owner, repo; auth = AnonymousAuth())
```
- `owner` is a GitHub login
- `repo` is a repository name
- `user` is a GitHub login
