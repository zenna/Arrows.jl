"Const specifies whether a given value is constant or not"
abstract type Const end
struct IsConst <: Const end
struct NotConst <: Const end
const known_const = IsConst()
const known_not_const = NotConst()

# "Constant Propagation"
# function constprop(arr::Arrow, props...)::Vector{PropType}
#   # If all the inputs are constant output is constant
#   if all((:const in keys(prop) for prop in props))
#     if any((prop[:const] == not_const for prop in props))
#
#   for prop in props
#     if :const in keys(prop)
#       push!(szs, prop[:size])
#     end
#   end
#   if isempty(szs)
#     [PropType() for i=1:length(⬧(arr))]
#   else
#     unionsz = meet(szs...)
#     [PropType(:size=>unionsz) for i=1:length(⬧(arr))]
#   end
# end
