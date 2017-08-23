using Arrows
using Base.Test

tests = [
    "arrow_tests"]

print_with_color(:blue, "Running tests:\n")

# if nworkers() > 1
#     rmprocs(workers())
# end
#
# if Base.JLOptions().code_coverage == 1
#     addprocs(Sys.CPU_CORES, exeflags = ["--code-coverage=user", "--inline=no", "--check-bounds=yes"])
# else
#     addprocs(Sys.CPU_CORES, exeflags = "--check-bounds=yes")
# end
#
# @everywhere using Arrows
# @everywhere using Base.Test
# @everywhere srand(345679)
# res = pmap(tests) do t
#     include(t*".jl")
#     nothing
# end



# Single thread
srand(345679)
res = map(tests) do t
  include(t*".jl")
  nothing
end

# print method ambiguities
println("Potentially stale exports: ")
display(Base.Test.detect_ambiguities(Arrows))
println()
