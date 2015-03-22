using GitHub, FactCheck

############################################## contents.jl ##############################################

# gh_auth = authenticate("123...")

facts("Read GitHub.jl Repo Files") do
  owner = "WestleyArgentum"
  repo = "GitHub.jl"
  context("Readme function returns readme file data") do
    readme_data = readme(gh_auth, owner, repo)
    @fact typeof(readme_data) => File
  end

  context("Contents function returns list of files") do
    contents_data = contents(gh_auth, owner, repo)
    @fact typeof(contents_data[1]) => File
  end

  # a = create_file(gh_auth, owner, repo, "test.json", "message",
  #                 {"content"=>"test"})
  # b = update_file(gh_auth, owner, repo, "test.json", "message",
  #                 a["content"].sha, {"content"=>"test1", "new"=> "key"})
  # c = delete_file(gh_auth, owner,repo, "test.json",
  #                 b["content"].sha, "message")
end
