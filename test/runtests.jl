using Arrows
using Base.Test
include("common.jl")

tests = [
    "comp_arrow.jl",
    "arrow_tests.jl",
    "policy.jl",
    "compose.jl",
    "misc.jl"]

print_with_color(:blue, "Running tests:\n")

# Single thread
srand(345679)
res = map(tests) do t
  include(t)
  nothing
end

# print method ambiguities
println("Potentially stale exports: ")
display(Base.Test.detect_ambiguities(Arrows))
println()
