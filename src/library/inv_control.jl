"Duplicates input `I` times dupl_n_(x) = (x,...x)"
struct InvDuplArrow{I} <: PrimArrow end

props{I}(::InvDuplArrow{I}) =
  [[Props(true, Symbol(:x, i), Array{Any}) for i=1:I]...,
   Props(false, :y, Array{Any})]

name{I}(::InvDuplArrow{I}) = Symbol(:inv_dupl_, I)
InvDuplArrow(n::Integer) = InvDuplArrow{n}()

"f(x, x) = (x,)"
function inv_dupl(xs...)
  first(xs)
end
