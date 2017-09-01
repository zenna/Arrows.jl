"Duplicates input `I` times dupl_n_(x) = (x,...x)"
struct InvDuplArrow{I} <: PrimArrow{I, 1} end

port_props{I}(::InvDuplArrow{I}) =
  [[PortProps(true, Symbol(:x, i), Array{Any}) for i=1:I]...,
   PortProps(false, :y, Array{Any})]

name(::InvDuplArrow) = :inv_dupl
InvDuplArrow(n::Integer) = InvDuplArrow{n}()