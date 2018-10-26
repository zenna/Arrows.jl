using Arrows
using Test
using Spec

include("common.jl")

exclude = ["policy.jl",
           "optimize.jl",
           "value.jl",
           "sym.jl",
           "array_test.jl"]

walktests(Arrows, exclude = exclude)