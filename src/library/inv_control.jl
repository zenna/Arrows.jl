"Duplicates input `I` times dupl_n_(x) = (x,...x)"
struct InvDuplArrow{I} <: PrimArrow end

port_props{I}(::InvDuplArrow{I}) =
  [[PortProps(true, Symbol(:x, i), Array{Any}) for i=1:I]...,
   PortProps(false, :y, Array{Any})]

name{I}(::InvDuplArrow{I}) = Symbol(:inv_dupl_, I)
InvDuplArrow(n::Integer) = InvDuplArrow{n}()

"f(x, x) = (x,)"
function inv_dupl(xs...)
  first(xs)
end
