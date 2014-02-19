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
- `repo` is the repository name
- `attempts` is the number of tries made before admitting defeat
