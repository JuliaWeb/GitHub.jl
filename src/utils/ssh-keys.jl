# This is a lightly-modified version of code in DocumenterTools.jl (thanks!)

"""
    pubkey, privkey = genkeys(; keycomment="Documenter")

Generate a public/private key pair. `pubkey` can be used as a [`deploykey`](@ref) and `privkey` as a [`secret`](@ref).
"""
function genkeys(; keycomment="Documenter")
    # Error checking. Do the required programs exist?
    if Sys.iswindows()
        success(`where where`)      || error("'where' not found.")
        success(`where ssh-keygen`) || error("'ssh-keygen' not found.")
    else
        success(`which which`)      || error("'which' not found.")
        success(`which ssh-keygen`) || error("'ssh-keygen' not found.")
    end


    directory = pwd()
    filename  = "github-private-key"

    isfile(filename) && error("temporary file '$(filename)' already exists in working directory")
    isfile("$(filename).pub") && error("temporary file '$(filename).pub' already exists in working directory")

    # Generate the ssh key pair.
    success(`ssh-keygen -N "" -C $keycomment -f $filename`) || error("failed to generate a SSH key pair.")

    pubkey = chomp(read("$filename.pub", String))
    privkey = base64encode(read(filename, String))
    rm("$filename.pub")
    rm(filename)

    return pubkey, privkey
end
