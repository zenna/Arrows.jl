"Duplicates input `I` times dupl_n_(x) = (x,...x)"
struct InvDuplArrow{I} <: PrimArrow{I, 1} end

port_attrs{I}(::InvDuplArrow{I}) =
  [[PortAttrs(true, Symbol(:x, i), Array{Any}) for i=1:I]...,
   PortAttrs(false, :y, Array{Any})]

name(::InvDuplArrow) = :inv_dupl
InvDuplArrow(n::Integer) = InvDuplArrow{n}()
