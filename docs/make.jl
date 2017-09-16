using Documenter, Arrows

makedocs()

deploydocs(
    repo = "github.com/zenna/Arrows.jl.git",
    julia="0.6",
    deps=nothing,
    make=nothing,
)
