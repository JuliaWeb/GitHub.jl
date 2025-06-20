################
# Secrets Type #
################

@ghdef mutable struct Secret
    name::Union{String, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
end

Secret(name::AbstractString) = Secret(Dict("name" => name))

namefield(secret::Secret) = check_disallowed_name_pattern(secret.name)

##################
# PublicKey Type #
##################

mutable struct PublicKey <: GitHubType
    key_id::Union{String, Nothing}
    key::Union{String, Nothing}
end

PublicKey(data::Dict) = json2github(PublicKey, data)

namefield(key::PublicKey) = key.key

function publickey(api::GitHubAPI, repo; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/actions/secrets/public-key"; options...)
    return PublicKey(result)
end

###############
# API Methods #
###############

@api_default function secret(api::GitHubAPI, repo, secret_obj; options...)
    result = gh_get_json(api, "/repos/$(name(repo))/actions/secrets/$(name(secret_obj))"; options...)
    return Secret(result)
end

@api_default function secrets(api::GitHubAPI, repo; options...)
    results, page_data = gh_get_paged_json(api, "/repos/$(name(repo))/actions/secrets"; options...)
    return map(Secret, results["secrets"]), page_data
end

@api_default function create_secret(api::GitHubAPI, repo, secretname; value, options...)
    key = publickey(api, repo; options...)
    k = SodiumSeal.KeyPair(key.key)
    encrypted = SodiumSeal.seal(base64encode(value), k)
    result = gh_put_json(api, "/repos/$(name(repo))/actions/secrets/$secretname"; params=Dict("encrypted_value"=>encrypted, "key_id"=>key.key_id), options...)
    return nothing
end

@api_default function delete_secret(api::GitHubAPI, repo, secretname; options...)
    gh_delete(api, "/repos/$(name(repo))/actions/secrets/$(name(secretname))"; options...)
    return nothing
end


"""
    secrets(repo; auth::Authorization) -> list::Vector{Secret}, page_data

List the names of secrets for `repo`. Requires that you [`authenticate`](@ref).

Secret values cannot be queried, only the names and the times of creation and most recent updates.
"""
secrets

"""
    create_secret(repo, name; value::String, auth::Authorization)

Create GitHub Action secret `name` with value `value`. Requires that you [`authenticate`](@ref).

`value` should be supplied as plain-text and will be encrypted via [libsodium](https://doc.libsodium.org/) for transmission.
"""
create_secret
