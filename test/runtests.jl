using Arrows
using Test
using Spec
using Pkg

# Add TestArrows
Pkg.develop(PackageSpec(url = joinpath(dirname(pathof(Arrows)), "..", "TestArrows")))

include("common.jl")

exclude = ["policy.jl",
           "optimize.jl",
           "value.jl",
           "sym.jl",
           "array_test.jl"]

walktests(Arrows, exclude = exclude)