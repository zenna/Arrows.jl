"Duplicates input `I` times dupl_n_(x) = (x,...x)"
struct MeanArrow{I} <: PrimArrow end

port_props{I}(::MeanArrow{I}) =
  [[PortProps(true, Symbol(:x, i), Array{Any}) for i=1:I]...,
   PortProps(false, :y, Array{Any})]

name(::MeanArrow) = :mean
MeanArrow(n::Integer) = MeanArrow{n}()

import Base.mean
mean(args...) = sum(args)/length(args)
