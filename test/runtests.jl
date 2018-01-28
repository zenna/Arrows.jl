using Arrows
using Base.Test
using Spec

include("common.jl")

exclude = ["policy.jl",
           "optimize.jl",
           "value.jl",
           "sym.jl"]

walktests(Arrows, exclude=exclude)