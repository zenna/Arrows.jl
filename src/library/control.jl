"Takes no input simple emits a `value::T`"
struct CondArrow <: PrimArrow end
props(::CondArrow) =   [Props(true, :i, Bool),
                             Props(true, :t, Real),
                             Props(true, :e, Real),
                             Props(false, :e, Real)]
name(::CondArrow) = :cond

"Duplicates input `O` times dupl_n_(x) = (x,...x)"
struct DuplArrow{O} <: PrimArrow end

props{O}(::DuplArrow{O}) =
  [Props(true, :x, Any),
   [Props(false, Symbol(:y, i), Any) for i=1:O]...]

name{O}(::DuplArrow{O}) = Symbol(:dupl_, O)
DuplArrow(n::Integer) = DuplArrow{n}()

"`(x, x, ..., x)` `n` times"
dupl(x, n)::Tuple = tuple((x for i = 1:n)...)

"f(x) = (x,)"
struct IdentityArrow <: PrimArrow end

props(::IdentityArrow) =
  [Props(true, :x, Any), Props(false, :y, Any)]

name(::IdentityArrow) = :identity

"ifelse(i, t, e)`"
struct IfElseArrow <: PrimArrow end
props(::IfElseArrow) =   [Props(true, :i, Bool),
                               Props(true, :t, Real),
                               Props(true, :e, Real),
                               Props(false, :y, Real)]
name(::IfElseArrow) = :ifelse
