using StaticTools
using Documenter

DocMeta.setdocmeta!(StaticTools, :DocTestSetup, :(using StaticTools); recursive=true)

makedocs(;
    modules=[StaticTools],
    authors="C. Brenhin Keller",
    repo="https://github.com/brenhinkeller/StaticTools.jl/blob/{commit}{path}#{line}",
    sitename="StaticTools.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://brenhinkeller.github.io/StaticTools.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/brenhinkeller/StaticTools.jl",
    devbranch="main",
)
