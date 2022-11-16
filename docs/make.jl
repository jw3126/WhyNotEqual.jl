using WhyNotEqual
using Documenter

DocMeta.setdocmeta!(WhyNotEqual, :DocTestSetup, :(using WhyNotEqual); recursive=true)

makedocs(;
    modules=[WhyNotEqual],
    authors="Jan Weidner <jw3126@gmail.com> and contributors",
    repo="https://github.com/jw3126/WhyNotEqual.jl/blob/{commit}{path}#{line}",
    sitename="WhyNotEqual.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jw3126.github.io/WhyNotEqual.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jw3126/WhyNotEqual.jl",
    devbranch="main",
)
