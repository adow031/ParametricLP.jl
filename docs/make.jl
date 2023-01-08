using Documenter, ParametricLP

makedocs(
    sitename = "ParametricLP",
    modules = [ParametricLP],
    clean = true,
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = ["ParametricLP" => "index.md", "API Reference" => "api.md"],
)

deploydocs(repo = "github.com/adow031/ParametricLP.jl.git", devurl = "docs")
