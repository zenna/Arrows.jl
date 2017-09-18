"Takes no input simple emits a `value::T`"
struct CondArrow <: PrimArrow end
port_props(::CondArrow) =   [PortProps(true, :i, Bool),
                             PortProps(true, :t, Real),
                             PortProps(true, :e, Real),
                             PortProps(false, :e, Real)]
name(::CondArrow) = :cond

"Duplicates input `O` times dupl_n_(x) = (x,...x)"
struct DuplArrow{O} <: PrimArrow end

port_props{O}(::DuplArrow{O}) =
  [PortProps(true, :x, Any),
   [PortProps(false, Symbol(:y, i), Any) for i=1:O]...]

name(::DuplArrow) = :dupl
DuplArrow(n::Integer) = DuplArrow{n}()

"`(x, x, ..., x)` `n` times"
dupl(x, n)::Tuple = tuple((x for i = 1:n)...)

"f(x) = (x,)"
struct IdentityArrow <: PrimArrow end

port_props(::IdentityArrow) =
  [PortProps(true, :x, Any), PortProps(false, :y, Any)]

name(::IdentityArrow) = :identity

"ifelse(i, t, e)`"
struct IfElseArrow <: PrimArrow end
port_props(::IfElseArrow) =   [PortProps(true, :i, Bool),
                               PortProps(true, :t, Real),
                               PortProps(true, :e, Real),
                               PortProps(false, :y, Real)]
name(::IfElseArrow) = :ifelse
