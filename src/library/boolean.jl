# Booleans #

"x & y"
struct AndArrow <: PrimArrow end
name(::AndArrow)::Symbol = :(&)
port_props(::AndArrow) = ineq_port_props

"x | y"
struct OrArrow <: PrimArrow end
name(::OrArrow)::Symbol = :|
port_props(::OrArrow) = ineq_port_props

"!x"
struct NotArrow <: PrimArrow end
name(::NotArrow)::Symbol = :!
port_props(::NotArrow) = ineq_port_props
