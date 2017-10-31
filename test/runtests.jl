using Arrows
using Base.Test
include("common.jl")

exclude = ["policy.jl",
           "tensorflow.jl",
           "optimize.jl"]
test_dir = joinpath(Pkg.dir("Arrows"), "test", "tests")
tests = setdiff(readdir(test_dir), exclude)

print_with_color(:blue, "Running tests:\n")

# Single thread
srand(345679)
res = map(tests) do t
  println("Testing: ", t)
  include(joinpath(test_dir, t))
  nothing
end

# print method ambiguities
println("Potentially stale exports: ")
display(Base.Test.detect_ambiguities(Arrows))
println()

# Submodule Tests
println("Running Compilation Target Tests")
include("../src/targets/tensorflow/test/runtests.jl")

println("Running Benchmark Tests")
include("../benchmarks/tests/runtests.jl")
