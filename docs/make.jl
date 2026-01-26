using Documenter, Behavior

makedocs(
    sitename="Behavior",
    pages = [
        "Home" => "index.md",
        "Usage" => "usage.md",
        "Tutorial" => "tutorial.md",
        "Functions" => "functions.md",
        "Gherkin Experimental" => "gherkin_experimental.md"
    ])

deploydocs(
    repo = "github.com/erikedin/Behavior.jl.git",
    devbranch = "master",
    push_preview = true,
)