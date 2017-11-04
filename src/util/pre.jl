"Most recently created method of generic function `func`"
newestmethod(func::Function) = sort(methods(func).ms, by=m->m.min_world)[end]

# macro testing(args...)
#   @show [typeof(arg) for arg in args]
# end
#
# @testing x + 1 ArgumentError("msg") x / 3

"Defien invariant - currently a dummy for documenation"
macro invariant(args...)
end
