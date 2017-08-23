"Takes no input simple emits a `value::T`"
struct CondArrow <: PrimArrow{3, 1} end
port_attrs(::CondArrow) =   [PortAttrs(true, :i, Array{Bool}),
                             PortAttrs(true, :t, Array{Real}),
                             PortAttrs(true, :e, Array{Real}),
                             PortAttrs(false, :e, Array{Real})]
name(::CondArrow) = :cond

"Duplicates input `I` times dupl_n_(x) = (x,...x)"
struct DuplArrow{I} <: PrimArrow{I, 1} end

port_attrs{I}(::DuplArrow{I}) =
  [PortAttrs(true, :x, Array{Any}),
   [PortAttrs(false, Symbol(:y, i), Array{Any}) for i=1:I]...]

name(::DuplArrow) = :dupl
DuplArrow(n::Integer) = DuplArrow{n}()

"f(x) = (x,)"
struct IdentityArrow <: PrimArrow{1, 1} end

port_attrs(::IdentityArrow) =
  [PortAttrs(true, :x, Array{Any}), PortAttrs(false, :y, Array{Any})]

name(::IdentityArrow) = :identity
