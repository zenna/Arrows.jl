"Takes no input simple emits a `value::T`"
struct CondArrow <: PrimArrow end
port_props(::CondArrow) =   [PortProps(true, :i, Array{Bool}),
                             PortProps(true, :t, Array{Real}),
                             PortProps(true, :e, Array{Real}),
                             PortProps(false, :e, Array{Real})]
name(::CondArrow) = :cond

"Duplicates input `O` times dupl_n_(x) = (x,...x)"
struct DuplArrow{O} <: PrimArrow end

port_props{O}(::DuplArrow{O}) =
  [PortProps(true, :x, Array{Any}),
   [PortProps(false, Symbol(:y, i), Array{Any}) for i=1:O]...]

name(::DuplArrow) = :dupl
DuplArrow(n::Integer) = DuplArrow{n}()

"f(x) = (x,)"
struct IdentityArrow <: PrimArrow end

port_props(::IdentityArrow) =
  [PortProps(true, :x, Array{Any}), PortProps(false, :y, Array{Any})]

name(::IdentityArrow) = :identity

"ifelse(i, t, e)`"
struct IfElseArrow <: PrimArrow end
port_props(::IfElseArrow) =   [PortProps(true, :i, Array{Bool}),
                               PortProps(true, :t, Array{Real}),
                               PortProps(true, :e, Array{Real}),
                               PortProps(false, :y, Array{Real})]
name(::IfElseArrow) = :ifelse
