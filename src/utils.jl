
# Utility -------

function github_obj_from_type(data::Dict)
    t = get(data, "type", nothing)

    if t == "User"
        return User(data)
    elseif t == "Organization"
        return Organization(data)
    end
end