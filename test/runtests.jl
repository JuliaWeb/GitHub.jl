using GitHub, FactCheck

############################################## contents.jl ##############################################

gh_auth = authenticate("123...")
myTestAccount = "..."
myTestRepo = "..."

facts("Read GitHub.jl Repo Files") do
  owner = "WestleyArgentum"
  repo = "GitHub.jl"
  context("Readme function returns readme file data") do
    readme_data = readme(gh_auth, owner, repo)
    @fact typeof(readme_data) => File
  end
end

facts("Create, Modify & Delete File") do
  context("Contents function returns list of files") do
    contents_data = contents(gh_auth, myTestAccount, myTestRepo)
    @fact typeof(contents_data[1]) => File
  end

  context("Create a file") do
    global newFile
    newFile = create_file(gh_auth, myTestAccount, myTestRepo,
                  "test.json", "message", {"content"=>"test"})
    @fact typeof(newFile["content"]) => File
  end

  context("Update existing file") do
    global updatedFile
    updatedFile = update_file(gh_auth, myTestAccount, myTestRepo,
                  "test.json", newFile["content"].sha, "message",
                  {"content"=>"test1"})
    @fact typeof(updatedFile["content"]) => File
  end

  context("Delete existing file") do
    deleteMessage = delete_file(gh_auth, myTestAccount, myTestRepo,
                  "test.json", updatedFile["content"].sha, "message")
    @fact typeof(deleteMessage) => Commit
  end
end
