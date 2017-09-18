using Arrows
using Base.Test
include("common.jl")

tests = [
    "comparrow.jl",
    "arrow_tests.jl",
    "compose.jl",
    "misc.jl",
    "loss.jl",
    "totalize.jl",
    "invert.jl",
    # "policy.jl",
    "value.jl"]

print_with_color(:blue, "Running tests:\n")

# Single thread
srand(345679)
res = map(tests) do t
  println("Testing: ", t)
  include(t)
  nothing
end

# print method ambiguities
println("Potentially stale exports: ")
display(Base.Test.detect_ambiguities(Arrows))
println()
