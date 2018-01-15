# Booleans #

"x & y"
struct AndArrow <: PrimArrow end
name(::AndArrow)::Symbol = :(&)
props(::AndArrow) = ineq_props

"x | y"
struct OrArrow <: PrimArrow end
name(::OrArrow)::Symbol = :|
props(::OrArrow) = ineq_props

"!x"
struct NotArrow <: PrimArrow end
name(::NotArrow)::Symbol = :!
props(::NotArrow) = ineq_props

"x ⊻ y"
struct XorArrow <: PrimArrow end
name(::XorArrow)::Symbol = :⊻
props(::XorArrow) = ineq_props
